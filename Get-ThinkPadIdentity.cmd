@echo off
setlocal

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$systemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct;" ^
    "$baseBoard = Get-CimInstance -ClassName Win32_BaseBoard;" ^
    "[pscustomobject][ordered]@{" ^
    "    MachineTypeModel = $systemProduct.Name;" ^
    "    ProductName = $systemProduct.Version;" ^
    "    SystemSerialNumber = $systemProduct.IdentifyingNumber;" ^
    "    UUID = $systemProduct.UUID;" ^
    "    BaseBoardProduct = $baseBoard.Product;" ^
    "    BaseBoardSerialNumber = $baseBoard.SerialNumber" ^
    "} | Format-List"

set "queryResult=%ERRORLEVEL%"
echo(
pause
exit /b %queryResult%
