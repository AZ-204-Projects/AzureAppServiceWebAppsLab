# 02a-run-local.ps1
# Build and run the web application locally for testing

. .\config.ps1

Write-Host "Starting Local Web Application..." -ForegroundColor Yellow

# Store current location
$originalLocation = Get-Location

try {
    # Check if project folder exists
    if (-not (Test-Path $WEB_PROJECT_FOLDER)) {
        throw "Project folder '$WEB_PROJECT_FOLDER' not found. Run 02-create-sample-app.ps1 first."
    }

    # Navigate to project directory
    Write-Host "Navigating to project folder: $WEB_PROJECT_FOLDER" -ForegroundColor Cyan
    Set-Location $WEB_PROJECT_FOLDER

    # Build the application
    Write-Host "Building application..." -ForegroundColor Cyan
    dotnet build --configuration Debug

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }

    Write-Host ""
    Write-Host "=== Local Application Starting ===" -ForegroundColor Green
    Write-Host "The application will start on HTTPS (typically https://localhost:7xxx)"
    Write-Host "Health check will be available at: /health"
    Write-Host "Press Ctrl+C to stop the application"
    Write-Host ""
    Write-Host "Note: Application Insights telemetry will not work locally without connection string"
    Write-Host ""

    # Run the application (this will block until Ctrl+C)
    dotnet run --configuration Debug
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Always return to original location
    Write-Host ""
    Write-Host "Returning to original location..." -ForegroundColor Cyan
    Set-Location $originalLocation
    Write-Host "Local testing complete." -ForegroundColor Yellow
}