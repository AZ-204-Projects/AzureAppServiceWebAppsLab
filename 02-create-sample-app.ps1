# 02-create-sample-app.ps1
# Create a sample ASP.NET Core application with monitoring integration

. .\config.ps1

Write-Host "Creating Sample Application..." -ForegroundColor Yellow

# Remove existing project directory if it exists (idempotent)
if (Test-Path $WEB_PROJECT_FOLDER) {
    Write-Warning "Project folder exists. Removing for fresh start..."
    Remove-Item -Recurse -Force $WEB_PROJECT_FOLDER
}

# Create new ASP.NET Core MVC project
Write-Host "Creating ASP.NET Core MVC project..." -ForegroundColor Cyan
dotnet new mvc -n $WEB_PROJECT_FOLDER

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to create ASP.NET Core project" 
}

# Navigate to project directory
Set-Location $WEB_PROJECT_FOLDER

# Add Application Insights SDK for telemetry
Write-Host "Adding Application Insights package..." -ForegroundColor Cyan
dotnet add package Microsoft.ApplicationInsights.AspNetCore

# Add health checks for monitoring endpoints
Write-Host "Adding health checks package..." -ForegroundColor Cyan
dotnet add package Microsoft.Extensions.Diagnostics.HealthChecks

# Add logging enhancements
Write-Host "Adding logging packages..." -ForegroundColor Cyan
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.ApplicationInsights

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to add required packages" 
}

Set-Location ..
Write-Host "Sample application created successfully!" -ForegroundColor Green
