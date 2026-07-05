param(
  [Parameter(Mandatory = $true)]
  [string]$EmailA,
  [Parameter(Mandatory = $true)]
  [string]$PasswordA,
  [Parameter(Mandatory = $true)]
  [string]$EmailB,
  [Parameter(Mandatory = $true)]
  [string]$PasswordB,
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabasePublishableKey = $env:SUPABASE_PUBLISHABLE_KEY,
  [switch]$IncludeCoupon
)

$ErrorActionPreference = "Stop"

$envFile = Join-Path $PSScriptRoot "..\.env"
if (Test-Path -LiteralPath $envFile) {
  foreach ($line in Get-Content -LiteralPath $envFile) {
    if ($line -match "^\s*#" -or $line -notmatch "=") {
      continue
    }

    $name, $value = $line.Split("=", 2)
    if ($name -eq "SUPABASE_URL" -and [string]::IsNullOrWhiteSpace($SupabaseUrl)) {
      $SupabaseUrl = $value.Trim()
    }
    if ($name -eq "SUPABASE_PUBLISHABLE_KEY" -and [string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
      $SupabasePublishableKey = $value.Trim()
    }
  }
}

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  throw "Missing Supabase URL. Pass -SupabaseUrl or set SUPABASE_URL."
}

if ([string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
  throw "Missing Supabase publishable/anon key. Pass -SupabasePublishableKey or set SUPABASE_PUBLISHABLE_KEY."
}

function New-JsonBody($value) {
  return ($value | ConvertTo-Json -Depth 10 -Compress)
}

function Invoke-SupaJson($method, $pathAndQuery, $token, $body = $null, $prefer = $null) {
  $headers = @{
    apikey = $SupabasePublishableKey
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
    "Accept-Profile" = "public"
    "Content-Profile" = "public"
  }
  if ($prefer) {
    $headers["Prefer"] = $prefer
  }

  $params = @{
    Uri = "${SupabaseUrl}${pathAndQuery}"
    Method = $method
    Headers = $headers
    TimeoutSec = 30
  }
  if ($null -ne $body) {
    $params.Body = (New-JsonBody $body)
  }

  return Invoke-RestMethod @params
}

function Login($email, $password) {
  return Invoke-RestMethod `
    -Uri "${SupabaseUrl}/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $SupabasePublishableKey; "Content-Type" = "application/json" } `
    -Method Post `
    -Body (New-JsonBody @{ email = $email; password = $password }) `
    -TimeoutSec 30
}

function Add-Check($name, $ok, $detail = "") {
  $script:checks.Add([PSCustomObject]@{
      Step = $name
      Ok = $ok
      Detail = $detail
    }) | Out-Null
}

$checks = [System.Collections.Generic.List[object]]::new()
$stamp = Get-Date -Format "yyyyMMddHHmmss"

$sessionA = Login $EmailA $PasswordA
$sessionB = Login $EmailB $PasswordB
$tokenA = $sessionA.access_token
$tokenB = $sessionB.access_token
$userA = $sessionA.user.id
$userB = $sessionB.user.id

Add-Check "login_A" (-not [string]::IsNullOrWhiteSpace($tokenA)) $userA
Add-Check "login_B" (-not [string]::IsNullOrWhiteSpace($tokenB)) $userB

foreach ($session in @($sessionA, $sessionB)) {
  $profile = Invoke-SupaJson "Get" "/rest/v1/profiles?id=eq.$($session.user.id)&select=*" $session.access_token
  if (@($profile).Count -eq 0) {
    $inserted = Invoke-SupaJson "Post" "/rest/v1/profiles?select=*" $session.access_token @{
      id = $session.user.id
      nickname = "Smoke User"
    } "return=representation"
    Add-Check "profile_created" (@($inserted).Count -gt 0) $session.user.id
  } else {
    Add-Check "profile_exists" $true $session.user.id
  }
}

$couple = $null
$couplesA = Invoke-SupaJson "Get" "/rest/v1/couples?select=*&status=in.(pending,active)" $tokenA
if (@($couplesA).Count -gt 0) {
  $couple = @($couplesA)[0]
  Add-Check "couple_found_for_A" $true "$($couple.id) / $($couple.status)"
} else {
  $invite = Invoke-SupaJson "Post" "/rest/v1/rpc/create_couple_invite" $tokenA @{}
  $inviteRow = @($invite)[0]
  Add-Check "invite_created_by_A" (-not [string]::IsNullOrWhiteSpace($inviteRow.invite_code)) $inviteRow.invite_code
  $bound = Invoke-SupaJson "Post" "/rest/v1/rpc/bind_couple" $tokenB @{
    invite_code_input = $inviteRow.invite_code
  }
  $couple = @($bound)[0]
  Add-Check "invite_bound_by_B" ($couple.status -eq "active") "$($couple.id) / $($couple.status)"
}

if ($couple.status -eq "pending") {
  $bound = Invoke-SupaJson "Post" "/rest/v1/rpc/bind_couple" $tokenB @{
    invite_code_input = $couple.invite_code
  }
  $couple = @($bound)[0]
  Add-Check "pending_invite_bound_by_B" ($couple.status -eq "active") "$($couple.id) / $($couple.status)"
}

if ($couple.status -ne "active") {
  throw "Couple is not active."
}

$coupleId = $couple.id
$couplesB = Invoke-SupaJson "Get" "/rest/v1/couples?select=*&status=eq.active" $tokenB
Add-Check "couple_visible_to_B" (@($couplesB).Count -gt 0) $coupleId

$todo = @(Invoke-SupaJson "Post" "/rest/v1/todos?select=*" $tokenA @{
    couple_id = $coupleId
    title = "Codex smoke todo $stamp"
  } "return=representation")[0]
Add-Check "todo_insert_A" (-not [string]::IsNullOrWhiteSpace($todo.id)) $todo.id
$todoUpdated = @(Invoke-SupaJson "Patch" "/rest/v1/todos?id=eq.$($todo.id)&select=*" $tokenB @{
    is_done = $true
  } "return=representation")[0]
Add-Check "todo_update_B" ($todoUpdated.is_done -eq $true) $todo.id
Invoke-SupaJson "Delete" "/rest/v1/todos?id=eq.$($todo.id)" $tokenA | Out-Null

if ($IncludeCoupon) {
  $coupon = @(Invoke-SupaJson "Post" "/rest/v1/coupons?select=*" $tokenA @{
      couple_id = $coupleId
      receiver_id = $userB
      title = "Codex smoke coupon $stamp"
      description = "temporary backend smoke check"
    } "return=representation")[0]
  Add-Check "coupon_issue_A_to_B" (-not [string]::IsNullOrWhiteSpace($coupon.id)) $coupon.id
  $couponUsed = Invoke-SupaJson "Post" "/rest/v1/rpc/use_coupon" $tokenB @{
    coupon_id_input = $coupon.id
  }
  Add-Check "coupon_use_B" ($couponUsed.status -eq "used") $coupon.id
} else {
  Add-Check "coupon_skipped" $true "Use -IncludeCoupon to test coupon issue/use. It leaves a used coupon."
}

$journal = @(Invoke-SupaJson "Post" "/rest/v1/journals?select=*" $tokenA @{
    couple_id = $coupleId
    mood = "ok"
    content = "Codex smoke journal $stamp"
  } "return=representation")[0]
Add-Check "journal_insert_A" (-not [string]::IsNullOrWhiteSpace($journal.id)) $journal.id
$journalUpdated = @(Invoke-SupaJson "Patch" "/rest/v1/journals?id=eq.$($journal.id)&select=*" $tokenA @{
    mood = "great"
    content = "Codex smoke journal updated $stamp"
  } "return=representation")[0]
Add-Check "journal_update_A" ($journalUpdated.mood -eq "great") $journal.id
Invoke-SupaJson "Delete" "/rest/v1/journals?id=eq.$($journal.id)" $tokenA | Out-Null

$anniversary = @(Invoke-SupaJson "Post" "/rest/v1/anniversaries?select=*" $tokenA @{
    couple_id = $coupleId
    title = "Codex smoke anniversary $stamp"
    event_date = "2026-07-05"
    type = "custom"
    repeat_yearly = $false
  } "return=representation")[0]
Add-Check "anniversary_insert_A" (-not [string]::IsNullOrWhiteSpace($anniversary.id)) $anniversary.id
$anniversaryUpdated = @(Invoke-SupaJson "Patch" "/rest/v1/anniversaries?id=eq.$($anniversary.id)&select=*" $tokenB @{
    repeat_yearly = $true
  } "return=representation")[0]
Add-Check "anniversary_update_B" ($anniversaryUpdated.repeat_yearly -eq $true) $anniversary.id
Invoke-SupaJson "Delete" "/rest/v1/anniversaries?id=eq.$($anniversary.id)" $tokenB | Out-Null

$mealPlan = @(Invoke-SupaJson "Post" "/rest/v1/meal_plans?select=*" $tokenA @{
    couple_id = $coupleId
    meal_date = "2026-07-05"
    meal_type = "snack"
    content = "Codex smoke meal plan $stamp"
  } "return=representation")[0]
Add-Check "meal_plan_insert_A" (-not [string]::IsNullOrWhiteSpace($mealPlan.id)) $mealPlan.id
$mealPlanUpdated = @(Invoke-SupaJson "Patch" "/rest/v1/meal_plans?id=eq.$($mealPlan.id)&select=*" $tokenB @{
    is_done = $true
  } "return=representation")[0]
Add-Check "meal_plan_update_B" ($mealPlanUpdated.is_done -eq $true) $mealPlan.id
Invoke-SupaJson "Delete" "/rest/v1/meal_plans?id=eq.$($mealPlan.id)" $tokenB | Out-Null

$downloadDir = "C:\src\downloads"
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
$tmpPng = Join-Path $downloadDir "codex-smoke-$stamp.png"
$pngBytes = [byte[]](
  0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x00,0x00,0x00,0x0D,
  0x49,0x48,0x44,0x52,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,
  0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,0x89,0x00,0x00,
  0x00,0x0A,0x49,0x44,0x41,0x54,0x78,0x9C,0x63,0x00,0x01,
  0x00,0x00,0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,0x00,
  0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,0x42,0x60,0x82
)
[System.IO.File]::WriteAllBytes($tmpPng, $pngBytes)
$photoPath = "$coupleId/$userA/codex-smoke-$stamp.png"
$uploadOutput = curl.exe -sS -w "HTTP_STATUS:%{http_code}" `
  -X POST "${SupabaseUrl}/storage/v1/object/meals/$photoPath" `
  -H "apikey: $SupabasePublishableKey" `
  -H "Authorization: Bearer $tokenA" `
  -H "x-upsert: true" `
  -H "Content-Type: image/png" `
  --data-binary "@$tmpPng"
$uploadStatus = ($uploadOutput -replace "(?s).*HTTP_STATUS:", "")
Add-Check "meal_photo_upload_A" ($uploadStatus -in @("200", "201")) "HTTP $uploadStatus"

$mealEntry = @(Invoke-SupaJson "Post" "/rest/v1/meal_entries?select=*" $tokenA @{
    couple_id = $coupleId
    meal_date = "2026-07-05"
    meal_type = "snack"
    photo_path = $photoPath
    note = "Codex smoke meal entry $stamp"
  } "return=representation")[0]
Add-Check "meal_entry_insert_A" (-not [string]::IsNullOrWhiteSpace($mealEntry.id)) $mealEntry.id

$signed = Invoke-RestMethod `
  -Uri "${SupabaseUrl}/storage/v1/object/sign/meals/$photoPath" `
  -Method Post `
  -Headers @{ apikey = $SupabasePublishableKey; Authorization = "Bearer $tokenB"; "Content-Type" = "application/json" } `
  -Body (New-JsonBody @{ expiresIn = 600 }) `
  -TimeoutSec 30
$signedUrl = if ($signed.signedURL) { $signed.signedURL } elseif ($signed.signedUrl) { $signed.signedUrl } else { "" }
Add-Check "meal_photo_signed_url_B" (-not [string]::IsNullOrWhiteSpace($signedUrl)) "signed url generated"

Invoke-SupaJson "Delete" "/rest/v1/meal_entries?id=eq.$($mealEntry.id)" $tokenA | Out-Null
Invoke-RestMethod `
  -Uri "${SupabaseUrl}/storage/v1/object/meals" `
  -Method Delete `
  -Headers @{ apikey = $SupabasePublishableKey; Authorization = "Bearer $tokenA"; "Content-Type" = "application/json" } `
  -Body (New-JsonBody @{ prefixes = @($photoPath) }) `
  -TimeoutSec 30 | Out-Null
Add-Check "meal_photo_delete_A" $true $photoPath

if (Test-Path -LiteralPath $tmpPng) {
  Remove-Item -LiteralPath $tmpPng -Force
}

$checks | Format-Table -AutoSize

if (($checks | Where-Object { -not $_.Ok }).Count -gt 0) {
  throw "One or more smoke checks failed."
}

Write-Output "SMOKE_OK couple_id=$coupleId"
