$ErrorActionPreference = "Stop"

$properties = Get-Content ".\server.properties"

$passwordLine = $properties | Where-Object {
    $_ -match '^rcon\.password='
} | Select-Object -First 1

$portLine = $properties | Where-Object {
    $_ -match '^rcon\.port='
} | Select-Object -First 1

if (!$passwordLine -or !$portLine) {
    Write-Host "No se encuentra la configuracion RCON."
    exit 1
}

$password = $passwordLine -replace '^rcon\.password=', ''
$port = [int]($portLine -replace '^rcon\.port=', '')

function Read-Exact($stream, $count) {
    $buffer = New-Object byte[] $count
    $offset = 0

    while ($offset -lt $count) {
        $read = $stream.Read($buffer, $offset, $count - $offset)
        if ($read -eq 0) { throw "Conexion cerrada." }
        $offset += $read
    }

    return ,$buffer
}

function Read-Packet($stream) {
    $lengthBytes = Read-Exact $stream 4
    $length = [BitConverter]::ToInt32($lengthBytes, 0)
    $data = Read-Exact $stream $length

    return @{
        ID = [BitConverter]::ToInt32($data, 0)
        Type = [BitConverter]::ToInt32($data, 4)
    }
}

function Send-Packet($stream, $id, $type, $message) {
    $body = [System.Text.Encoding]::UTF8.GetBytes($message + [char]0 + [char]0)
    $length = 4 + 4 + $body.Length

    $packet = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($packet)

    $writer.Write([int]$length)
    $writer.Write([int]$id)
    $writer.Write([int]$type)
    $writer.Write($body)
    $writer.Flush()

    $bytes = $packet.ToArray()
    $stream.Write($bytes, 0, $bytes.Length)

    $writer.Dispose()
    $packet.Dispose()
}

try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.ReceiveTimeout = 5000
    $client.SendTimeout = 5000
    $client.Connect("127.0.0.1", $port)

    $stream = $client.GetStream()

    Send-Packet $stream 1 3 $password
    $auth = Read-Packet $stream

    if ($auth.ID -ne 1) {
        throw "Autenticacion RCON fallida."
    }

    Send-Packet $stream 2 2 "stop"
    $response = Read-Packet $stream

    Write-Host "Comando STOP enviado correctamente."
    Write-Host "Esperando el cierre ordenado del servidor..."

    $stream.Close()
    $client.Close()
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}
