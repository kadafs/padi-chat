# Wait for PostgreSQL to start, then run validation

Write-Host "=== Waiting for PostgreSQL to Start ===" -ForegroundColor Cyan
Write-Host ""

$pgBin = "C:\Program Files\PostgreSQL\18\bin"
$maxAttempts = 30
$attempt = 0
$connected = $false

Write-Host "Checking PostgreSQL connection..." -ForegroundColor Yellow
Write-Host "(Make sure PostgreSQL is started via Services or pgAdmin)" -ForegroundColor Gray
Write-Host ""

while ($attempt -lt $maxAttempts -and -not $connected) {
    $attempt++
    Write-Host "Attempt $attempt/$maxAttempts..." -NoNewline
    
    # Try to connect
    $result = & "$pgBin\psql.exe" -U postgres -c "SELECT 1;" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $connected = $true
        Write-Host " ✓ Connected!" -ForegroundColor Green
        break
    } else {
        Write-Host " (not ready yet...)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if ($connected) {
    Write-Host ""
    Write-Host "✓ PostgreSQL is running!" -ForegroundColor Green
    Write-Host ""
    
    # Check if database exists
    Write-Host "Checking database 'chaskiq_dev'..." -ForegroundColor Yellow
    $dbCheck = & "$pgBin\psql.exe" -U postgres -lqt | Select-String "chaskiq_dev"
    
    if (-not $dbCheck) {
        Write-Host "Creating database 'chaskiq_dev'..." -ForegroundColor Yellow
        & "$pgBin\psql.exe" -U postgres -c "CREATE DATABASE chaskiq_dev;" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Database created!" -ForegroundColor Green
        }
    } else {
        Write-Host "✓ Database exists!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Running Tidio schema validation..." -ForegroundColor Cyan
    Write-Host ""
    
    $env:POSTGRES_DATABASE = "chaskiq_dev"
    $env:POSTGRES_USERNAME = "postgres"
    $env:POSTGRES_PASSWORD = ""
    
    ruby validate_postgres_schema.rb
} else {
    Write-Host ""
    Write-Host "✗ Could not connect to PostgreSQL after $maxAttempts attempts." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure PostgreSQL is started:" -ForegroundColor Yellow
    Write-Host "  1. Open Services (services.msc)" -ForegroundColor White
    Write-Host "  2. Find 'PostgreSQL' service and start it" -ForegroundColor White
    Write-Host "  3. Or open pgAdmin 4 from Start Menu" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again." -ForegroundColor Yellow
    exit 1
}

