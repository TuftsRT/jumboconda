$infile = "specs.txt"
$outfile = "packages.csv"

New-Item -Path $outfile -ItemType "File" -Force | Out-Null
Add-Content -Path $outfile -Value "package,version,build"

(Get-Content -Path $infile).Replace( "=", ",") |
    Select-Object -Skip 3 |
    Add-Content -Path $outfile
