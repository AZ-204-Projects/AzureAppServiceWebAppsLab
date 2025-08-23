# 04-deploy-application.ps1
# Deploy the application to Azure App Service

. .\config.ps1

Write-Host "Deploying Application to Azure..." -ForegroundColor Yellow

# Build the application in Release configuration
Write-Host "Building application..." -ForegroundColor Cyan
Set-Location $WEB_PROJECT_FOLDER

dotnet publish -c Release -o ./publish
if ($LASTEXITCODE -ne 0) { 
    throw "Failed to build application" 
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Cyan
Compress-Archive -Path "./publish/*" -DestinationPath "../deployment.zip" -Force

Set-Location ..

# Deploy to Azure App Service using ZIP deployment
Write-Host "Deploying to App Service..." -ForegroundColor Cyan
az webapp deployment source config-zip `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --src "deployment.zip"

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy application" 
}

# Clean up deployment artifacts
Remove-Item "deployment.zip" -ErrorAction SilentlyContinue

# Get the application URL
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Application URL: https://$webAppUrl"
Write-Host "Health Check: https://$webAppUrl/health"
Write-Host ""
Write-Host "Allow 2-3 minutes for application to start completely."
Write-Host ""