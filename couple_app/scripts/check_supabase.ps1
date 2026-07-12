param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabasePublishableKey = $env:SUPABASE_PUBLISHABLE_KEY
)

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

$tables = @(
  "profiles",
  "couples",
  "todos",
  "coupons",
  "journals",
  "anniversaries",
  "meal_entries",
  "meal_comments",
  "meal_plans"
)

Write-Output "Tables"
$tableRows = foreach ($table in $tables) {
  $output = curl.exe -sS -w "HTTP_STATUS:%{http_code}" `
    "$SupabaseUrl/rest/v1/$table`?select=*&limit=1" `
    -H "apikey: $SupabasePublishableKey" `
    -H "Authorization: Bearer $SupabasePublishableKey" `
    -H "Accept-Profile: public"
  $status = ($output -replace "(?s).*HTTP_STATUS:", "")
  $body = ($output -replace "HTTP_STATUS:\d+$", "")
  [PSCustomObject]@{ Table = $table; Status = $status; Body = $body }
}
$tableRows | Format-Table -AutoSize

Write-Output ""
Write-Output "Auth Settings"
$settingsJson = curl.exe -sS "$SupabaseUrl/auth/v1/settings" `
  -H "apikey: $SupabasePublishableKey"
$settings = $settingsJson | ConvertFrom-Json
[PSCustomObject]@{
  EmailProviderEnabled = $settings.external.email
  SignupDisabled = $settings.disable_signup
  EmailAutoconfirm = $settings.mailer_autoconfirm
} | Format-Table -AutoSize
