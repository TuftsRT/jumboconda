$hook = "C:\JumboConda\shell\condabin\conda-hook.ps1"
$hash = "A932372355874975920B2FE83FFFE7F1F5CF52214F34DCDBC10409674D5E57A9"
$algo = "SHA256"
if (Test-Path $hook) {
    Invoke-Expression $hook
    $out = Invoke-Conda list --export
    $stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stream)
    $writer.write($out)
    $writer.Flush()
    $stream.Position = 0
    if ((Get-FileHash -InputStream $stream -Algorithm $algo).Hash -eq $hash) {
        Write-Host "Fully Installed"
    } else {
        Write-Host "Corrupted Installation"
    }
} else {
    Write-Host "Not Installed"
}
