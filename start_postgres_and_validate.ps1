# PowerShell script to start PostgreSQL and validate Tidio schema

Write-Host "=== Starting PostgreSQL and Running Tidio Validation ===" -ForegroundColor Cyan
Write-Host ""

$pgBin = "C:\Program Files\PostgreSQL\18\bin"
$pgData = "C:\Program Files\PostgreSQL\18\data"

# Check if PostgreSQL is already running
Write-Host "Checking if PostgreSQL is running..." -ForegroundColor Yellow
$testConnection = & "$pgBin\psql.exe" -U postgres -c "SELECT 1;" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ PostgreSQL is already running!" -ForegroundColor Green
} else {
    Write-Host "PostgreSQL is not running. Attempting to start..." -ForegroundColor Yellow
    
    # Try to start PostgreSQL
    if (Test-Path "$pgBin\pg_ctl.exe") {
        Write-Host "Starting PostgreSQL service..." -ForegroundColor Yellow
        & "$pgBin\pg_ctl.exe" start -D "$pgData" -w
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ PostgreSQL started successfully!" -ForegroundColor Green
            Start-Sleep -Seconds 2
        } else {
            Write-Host "✗ Could not start PostgreSQL automatically." -ForegroundColor Red
            Write-Host ""
            Write-Host "Please start PostgreSQL manually:" -ForegroundColor Yellow
            Write-Host "  1. Open pgAdmin 4 from Start Menu, OR" -ForegroundColor White
            Write-Host "  2. Run: Start-Process '$pgBin\pg_ctl.exe' -ArgumentList 'start','-D','$pgData'" -ForegroundColor White
            Write-Host "  3. Or start the PostgreSQL service from Services (services.msc)" -ForegroundColor White
            exit 1
        }
    } else {
        Write-Host "✗ PostgreSQL binaries not found at: $pgBin" -ForegroundColor Red
        exit 1
    }
}

# Check if database exists
Write-Host ""
Write-Host "Checking if database 'chaskiq_dev' exists..." -ForegroundColor Yellow
$dbCheck = & "$pgBin\psql.exe" -U postgres -lqt | Select-String "chaskiq_dev"

if (-not $dbCheck) {
    Write-Host "Database 'chaskiq_dev' does not exist. Creating..." -ForegroundColor Yellow
    & "$pgBin\psql.exe" -U postgres -c "CREATE DATABASE chaskiq_dev;" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database 'chaskiq_dev' created!" -ForegroundColor Green
    } else {
        Write-Host "✗ Could not create database. You may need to create it manually:" -ForegroundColor Red
        Write-Host "  psql -U postgres -c 'CREATE DATABASE chaskiq_dev;'" -ForegroundColor White
    }
} else {
    Write-Host "✓ Database 'chaskiq_dev' exists!" -ForegroundColor Green
}

# Run validation
Write-Host ""
Write-Host "Running Tidio schema validation..." -ForegroundColor Cyan
Write-Host ""

$env:POSTGRES_DATABASE = "chaskiq_dev"
$env:POSTGRES_USERNAME = "postgres"
$env:POSTGRES_PASSWORD = ""

ruby validate_postgres_schema.rb

Write-Host ""
Write-Host "=== Validation Complete ===" -ForegroundColor Cyan
