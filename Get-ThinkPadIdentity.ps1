# Read the system and board identifiers that Windows exposes through CIM.
$systemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop
$baseBoard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction Stop

[pscustomobject]@{
    MachineTypeModel      = $systemProduct.Name
    ProductName           = $systemProduct.Version
    SystemSerialNumber    = $systemProduct.IdentifyingNumber
    UUID                  = $systemProduct.UUID
    BaseBoardProduct      = $baseBoard.Product
    BaseBoardSerialNumber = $baseBoard.SerialNumber
}
