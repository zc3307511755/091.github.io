param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabasePublishableKey = $env:SUPABASE_PUBLISHABLE_KEY,
  [string]$Flutter = "C:\src\flutter\bin\flutter.bat"
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

& $Flutter run `
  --dart-define="SUPABASE_URL=$SupabaseUrl" `
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SupabasePublishableKey"

exit $LASTEXITCODE
