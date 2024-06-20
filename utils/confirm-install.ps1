$hook = "C:\JumboConda\shell\condabin\conda-hook.ps1"
$hash = "98C7D8A7233CD2D12A86C94ACCCFFE6EFF9BAD2CFC2937FDF09AABDE93E20857"
$algo = "SHA256"
if (Test-Path $hook) {
    Invoke-Expression $hook
    $out = [string](Invoke-Conda list --export)
    $stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stream)
    $writer.write($out)
    $writer.Flush()
    $stream.Position = 0
    if ((Get-FileHash -InputStream $stream -Algorithm $algo).Hash -eq $hash) {
        Write-Host "Fully Installed"
    } else {
        Write-Host "Outdated or Corrupted Installation"
    }
} else {
    Write-Host "Not Installed"
}
