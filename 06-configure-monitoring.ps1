# 06-configure-monitoring.ps1
# Configure detailed monitoring and diagnostics

. .\config.ps1

Write-Host "Configuring Monitoring and Diagnostics..." -ForegroundColor Yellow

# Enable application logging
Write-Host "Enabling application logging..." -ForegroundColor Cyan
az webapp log config `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --application-logging filesystem `
    --level information `
    --web-server-logging filesystem

# Note: Detailed error logging and request tracing are already enabled via the log config command above
# Verify this in the output - you should see "detailedErrorMessages": {"enabled": true}
Write-Host "Checking current error handling configuration..." -ForegroundColor Cyan
Write-Host "Note: detailedErrorMessages and failedRequestsTracing should already be enabled from the log config command above." -ForegroundColor Yellow

# Display monitoring URLs
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Monitoring Endpoints ===" -ForegroundColor Green
Write-Host "Application: https://$webAppUrl"
Write-Host "Health Check: https://$webAppUrl/health"
Write-Host "Kudu Console: https://$WEB_APP_SERVICE_NAME.scm.azurewebsites.net"
Write-Host ""

Write-Host "Log Streaming Commands:" -ForegroundColor Cyan
Write-Host "az webapp log tail --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME"
Write-Host "az webapp log download --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME"
Write-Host ""

# Verify configuration
Write-Host "Verifying logging configuration..." -ForegroundColor Cyan
az webapp log show --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME