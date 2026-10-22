# Vestora Web Deploy Script
# Usage: .\tools\deploy_web.ps1 [-Target vercel|firebase|local]

param (
    [string]$Target = "local"
)

Write-Host "✨ [1/3] Building Vestora Web PWA Release..." -ForegroundColor Cyan
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Copy 404.html to build/web
if (Test-Path "web/404.html") {
    Copy-Item "web/404.html" -Destination "build/web/404.html" -Force
}

Write-Host "✅ [2/3] Build finished successfully in mobile_app/build/web" -ForegroundColor Green

if ($Target -eq "vercel") {
    Write-Host "🚀 [3/3] Deploying to Vercel..." -ForegroundColor Cyan
    vercel --prod
} elseif ($Target -eq "firebase") {
    Write-Host "🔥 [3/3] Deploying to Firebase Hosting..." -ForegroundColor Cyan
    firebase deploy --only hosting
} else {
    Write-Host "🌐 [3/3] Static files ready for any web server / hosting at: mobile_app/build/web" -ForegroundColor Green
    Write-Host "💡 To preview locally run: python run_server.py" -ForegroundColor Yellow
}
