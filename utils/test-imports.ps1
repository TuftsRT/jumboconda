Get-Content ".\importlist.txt" | ForEach-Object {
    Write-Output $_
    Start-Process "python" -ArgumentList "-c `"import $_`"" -NoNewWindow -Wait
}
