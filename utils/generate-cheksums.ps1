Get-ChildItem -Path ".\*" -Include "*.exe" | ForEach-Object {
    New-Item -Path "$_.sha256" -ItemType "file" -Force `
        -Value (Get-FileHash -Path $_ -Algorithm "SHA256").Hash
}
