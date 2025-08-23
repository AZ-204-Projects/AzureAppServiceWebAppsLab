# 10-performance-testing.ps1
# Generate load to test autoscaling functionality

. .\config.ps1

Write-Host "Performance Testing and Monitoring..." -ForegroundColor Yellow

$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host "Application URL: https://$webAppUrl" -ForegroundColor Cyan

# Simple load testing function (for educational purposes)
function Start-LoadTest {
    param(
        [string]$Url,
        [int]$Requests = 100,
        [int]$Concurrent = 10
    )
    
    Write-Host "Generating load: $Requests requests with $Concurrent concurrent connections..." -ForegroundColor Yellow
    
    $jobs = @()
    for ($i = 1; $i -le $Concurrent; $i++) {
        $job = Start-Job -ScriptBlock {
            param($url, $requestsPerJob)
            
            for ($j = 1; $j -le $requestsPerJob; $j++) {
                try {
                    Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing | Out-Null
                    Write-Host "Job $using:i - Request $j completed"
                }
                catch {
                    Write-Host "Job $using:i - Request $j failed: $($_.Exception.Message)"
                }
                Start-Sleep -Milliseconds 100
            }
        } -ArgumentList $Url, ($Requests / $Concurrent)
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $jobs | Wait-Job
    $jobs | Remove-Job
    
    Write-Host "Load test completed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Performance Testing Options ===" -ForegroundColor Green
Write-Host "1. Monitor current metrics"
Write-Host "2. Run light load test (educational purposes)"
Write-Host "3. View autoscale configuration"
Write-Host "4. Stream application logs"
Write-Host ""

$choice = Read-Host "Select option (1-4, or Enter to skip)"

switch ($choice) {
    "1" {
        Write-Host "Current application metrics..." -ForegroundColor Cyan
        az monitor metrics list `
            --resource-group $RG_NAME `
            --resource $WEB_APP_SERVICE_NAME `
            --resource-type "Microsoft.Web/sites" `
            --metric "CpuPercentage,MemoryPercentage,Requests" `
            --interval PT5M `
            --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")
    }
    
    "2" {
        Write-Host "Starting educational load test..." -ForegroundColor Yellow
        Write-Host "This will generate moderate load to demonstrate autoscaling." -ForegroundColor Yellow
        Start-LoadTest -Url "https://$webAppUrl" -Requests 50 -Concurrent 5
        
        Write-Host "Monitor scaling activity:" -ForegroundColor Cyan
        Write-Host "az monitor autoscale show --resource-group $RG_NAME --name $AUTOSCALE_PROFILE_NAME"
    }
    
    "3" {
        Write-Host "Current autoscale configuration..." -ForegroundColor Cyan
        az monitor autoscale show `
            --resource-group $RG_NAME `
            --name $AUTOSCALE_PROFILE_NAME `
            --output table
    }
    
    "4" {
        Write-Host "Streaming application logs (Ctrl+C to stop)..." -ForegroundColor Cyan
        az webapp log tail `
            --resource-group $RG_NAME `
            --name $WEB_APP_SERVICE_NAME
    }
    
    default {
        Write-Host "Skipping performance testing." -ForegroundColor Yellow
    }
}
