@echo off
setlocal
set "PS_URL=https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1"
set "PS_FILE=%TEMP%\rai-install-%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%PS_URL%', '%PS_FILE%'); & '%PS_FILE%'"
del "%PS_FILE%" 2>nul
endlocal
