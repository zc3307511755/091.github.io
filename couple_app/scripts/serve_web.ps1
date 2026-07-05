param(
  [int]$Port = 8080,
  [string]$WebRoot = "build\web"
)

$resolvedRoot = Resolve-Path -LiteralPath $WebRoot -ErrorAction SilentlyContinue
if (-not $resolvedRoot) {
  throw "Web build not found at $WebRoot. Run scripts\build_web.ps1 first."
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  throw "Python is required to serve the web build locally."
}

Write-Output "Serving $($resolvedRoot.Path) at http://localhost:$Port"
& $python.Source -m http.server $Port --directory $resolvedRoot.Path
