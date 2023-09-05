#Requires -RunAsAdministrator

$condaRoot = Join-Path $env:SystemDrive "JumboConda"

$pythonPath = (Join-Path $condaroot "python.exe").Replace("\", "\\")

$settingsContent = @"
{
  "checkForUpdatesAutomatically": false,
  "installUpdatesAutomatically": false,
  "pythonPath": "$pythonPath",
  "serverEnvVars": {}
}
"@

Get-ChildItem (Join-Path $env:SystemDrive "Users") -Force -Directory `
-Exclude "All Users","Default User","Public" | ForEach-Object {
    $settingsDir = Join-Path $_.FullName "AppData\Roaming\jupyterlab-desktop"
    New-Item -ItemType Directory -Force -Path $settingsDir
    $settingsFile = (Join-Path $settingsDir "settings.json")
    New-Item -ItemType File -Force -Path $settingsFile -Value $settingsContent
}
