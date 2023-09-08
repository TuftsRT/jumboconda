foreach ($pkg in Get-Content ".\importlist.txt") {
    Write-Output $pkg
    Start-Process "python" -ArgumentList "-c `"import $pkg`"" -NoNewWindow -Wait
}
