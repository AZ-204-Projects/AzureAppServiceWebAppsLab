# 08-configure-deployment-slots.ps1
# Configure deployment slots for blue-green deployments

. .\config.ps1

Write-Host "Configuring Deployment Slots..." -ForegroundColor Yellow

# Note: Deployment slots require Standard tier or higher
# Create staging deployment slot
Write-Host "Creating staging deployment slot..." -ForegroundColor Cyan
az webapp deployment slot create `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME

if ($LASTEXITCODE -ne 0) { 
    Write-Warning "Failed to create deployment slot. Deployment slots require Standard tier or higher."
    return
}

# Configure slot-specific settings (optional)
Write-Host "Configuring slot settings..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME `
    --settings "ASPNETCORE_ENVIRONMENT=Staging" "SlotName=Staging"

# Get staging slot URL
$stagingUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Deployment Slots ===" -ForegroundColor Green
Write-Host "Production: https://$WEB_APP_SERVICE_NAME.azurewebsites.net"
Write-Host "Staging: https://$stagingUrl"
Write-Host ""

Write-Host "Deployment Commands:" -ForegroundColor Cyan
Write-Host "Deploy to staging:"
Write-Host "az webapp deployment source config-zip --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --slot $DEPLOYMENT_SLOT_NAME --src deployment.zip"
Write-Host ""
Write-Host "Swap slots (zero-downtime deployment):"
Write-Host "az webapp deployment slot swap --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --slot $DEPLOYMENT_SLOT_NAME --target-slot production"
Write-Host ""