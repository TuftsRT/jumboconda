$hook = "C:\JumboConda\shell\condabin\conda-hook.ps1"
$hash = "C9D7A3D8A38BD9A7C9AF6874EDD43DE4D084BCECD26B1B2319277EEC1797E5D4"
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
