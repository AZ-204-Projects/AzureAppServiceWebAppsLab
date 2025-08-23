# 05-configure-security.ps1
# Configure security settings and TLS

. .\config.ps1

Write-Host "Configuring Security Settings..." -ForegroundColor Yellow

# Configure HTTPS-only access
Write-Host "Enabling HTTPS-only access..." -ForegroundColor Cyan
az webapp update `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --https-only true

# Configure minimum TLS version
Write-Host "Setting minimum TLS version to 1.2..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --min-tls-version "1.2"

# Disable FTP deployment (security best practice)
Write-Host "Disabling FTP deployment..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --ftps-state "Disabled"

# Configure custom domain (optional - requires domain ownership)
# Write-Host "To configure custom domain:" -ForegroundColor Yellow
# Write-Host "az webapp config hostname add --webapp-name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME --hostname your-domain.com"

# Configure managed certificate (requires custom domain)
# Write-Host "To add managed SSL certificate:" -ForegroundColor Yellow  
# Write-Host "az webapp config ssl create --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --hostname your-domain.com"

Write-Host "Security configuration completed!" -ForegroundColor Green