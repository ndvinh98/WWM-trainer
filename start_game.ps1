# Start "Where Winds Meet" via Steam
# The game requires launching through Steam, so we use the steam:// protocol.

$steamUrl = "steam://rungameid/3564740"

Write-Host "Launching Where Winds Meet via Steam..." -ForegroundColor Cyan
Start-Process $steamUrl
Write-Host "Launch request sent. The game should start shortly." -ForegroundColor Green
