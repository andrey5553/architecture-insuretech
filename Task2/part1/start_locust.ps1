# Получаем URL сервиса
$url = "http://localhost:8080"

Write-Host "Testing URL: $url" -ForegroundColor Green
Write-Host "Starting Locust test..." -ForegroundColor Yellow

locust -H $url -u 1000 -t 10m --logfile locust_log.log --json-file locust_result.json --only-summary