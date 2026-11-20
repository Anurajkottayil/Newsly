Add-Type -AssemblyName System.Drawing

Write-Output "=== Android Legacy Icons ==="
Get-ChildItem -Path "D:\Newsly\android\app\src\main\res\mipmap-*" -Filter "ic_launcher.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{ Directory = $_.Directory.Name; File = $_.Name; Width = $img.Width; Height = $img.Height }
    $img.Dispose()
}

Write-Output "`n=== Android Round Icons ==="
Get-ChildItem -Path "D:\Newsly\android\app\src\main\res\mipmap-*" -Filter "ic_launcher_round.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{ Directory = $_.Directory.Name; File = $_.Name; Width = $img.Width; Height = $img.Height }
    $img.Dispose()
}

Write-Output "`n=== Android Adaptive Foreground ==="
Get-ChildItem -Path "D:\Newsly\android\app\src\main\res\mipmap-*" -Filter "ic_launcher_foreground.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{ Directory = $_.Directory.Name; File = $_.Name; Width = $img.Width; Height = $img.Height }
    $img.Dispose()
}

Write-Output "`n=== iOS AppIcon Catalog ==="
Get-ChildItem -Path "D:\Newsly\ios\Runner\Assets.xcassets\AppIcon.appiconset" -Filter "*.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{ File = $_.Name; Width = $img.Width; Height = $img.Height }
    $img.Dispose()
}
