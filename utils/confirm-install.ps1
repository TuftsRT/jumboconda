$hook = "C:\JumboConda\shell\condabin\conda-hook.ps1"
$hash = "DEDA9DCF6F93E6F052A83F8F8E7CD4FB9A0E5DF1E9950DA5D83FA07D989A85F8"
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
