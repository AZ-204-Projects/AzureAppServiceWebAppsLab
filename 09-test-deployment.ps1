# 09-test-deployment.ps1
# Test all configured features and functionality

. .\config.ps1

Write-Host "Testing Deployment..." -ForegroundColor Yellow

# Get web app URL
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host "Running comprehensive tests..." -ForegroundColor Cyan

# Test 1: Basic connectivity
Write-Host "1. Testing basic connectivity..." -ForegroundColor White
try {
    $response = Invoke-WebRequest -Uri "https://$webAppUrl" -Method GET -UseBasicParsing
    Write-Host "   ✓ Main page accessible (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Main page failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Health check endpoint
Write-Host "2. Testing health check..." -ForegroundColor White
try {
    $healthResponse = Invoke-WebRequest -Uri "https://$webAppUrl/health" -Method GET -UseBasicParsing
    Write-Host "   ✓ Health check passed (Status: $($healthResponse.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: HTTPS redirection
Write-Host "3. Testing HTTPS redirection..." -ForegroundColor White
try {
    $httpResponse = Invoke-WebRequest -Uri "http://$webAppUrl" -Method GET -UseBasicParsing -MaximumRedirection 0
    Write-Host "   ✗ HTTP should redirect to HTTPS" -ForegroundColor Red
}
catch {
    if ($_.Exception.Response.StatusCode -eq 301 -or $_.Exception.Response.StatusCode -eq 302) {
        Write-Host "   ✓ HTTP correctly redirects to HTTPS" -ForegroundColor Green
    } else {
        Write-Host "   ? Unexpected redirect behavior" -ForegroundColor Yellow
    }
}

# Test 4: Verify logging configuration
Write-Host "4. Verifying logging configuration..." -ForegroundColor White
az webapp log show --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "Application URL: https://$webAppUrl"
Write-Host "Health Endpoint: https://$webAppUrl/health"
Write-Host "Kudu Console: https://$WEB_APP_SERVICE_NAME.scm.azurewebsites.net"
Write-Host ""

Write-Host "Additional Testing Commands:" -ForegroundColor Cyan
Write-Host "Stream live logs: az webapp log tail --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME"
Write-Host "View metrics: az monitor metrics list --resource-group $RG_NAME --resource $WEB_APP_SERVICE_NAME --resource-type Microsoft.Web/sites"
Write-Host "Check autoscale status: az monitor autoscale show --resource-group $RG_NAME --name $AUTOSCALE_PROFILE_NAME"
Write-Host ""