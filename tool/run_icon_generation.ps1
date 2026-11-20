Add-Type -Path "D:\Newsly\tool\IconGenerator.cs" -ReferencedAssemblies System.Drawing

Write-Output "Generating Android legacy icons..."
[IconGenerator]::Render(48,  "D:\Newsly\android\app\src\main\res\mipmap-mdpi\ic_launcher.png", $false, $false)
[IconGenerator]::Render(72,  "D:\Newsly\android\app\src\main\res\mipmap-hdpi\ic_launcher.png", $false, $false)
[IconGenerator]::Render(96,  "D:\Newsly\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png", $false, $false)
[IconGenerator]::Render(144, "D:\Newsly\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png", $false, $false)
[IconGenerator]::Render(192, "D:\Newsly\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png", $false, $false)

Write-Output "Generating Android round icons..."
[IconGenerator]::Render(48,  "D:\Newsly\android\app\src\main\res\mipmap-mdpi\ic_launcher_round.png", $false, $true)
[IconGenerator]::Render(72,  "D:\Newsly\android\app\src\main\res\mipmap-hdpi\ic_launcher_round.png", $false, $true)
[IconGenerator]::Render(96,  "D:\Newsly\android\app\src\main\res\mipmap-xhdpi\ic_launcher_round.png", $false, $true)
[IconGenerator]::Render(144, "D:\Newsly\android\app\src\main\res\mipmap-xxhdpi\ic_launcher_round.png", $false, $true)
[IconGenerator]::Render(192, "D:\Newsly\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher_round.png", $false, $true)

Write-Output "Generating Android adaptive foreground icons..."
[IconGenerator]::Render(108, "D:\Newsly\android\app\src\main\res\mipmap-mdpi\ic_launcher_foreground.png", $true, $false)
[IconGenerator]::Render(162, "D:\Newsly\android\app\src\main\res\mipmap-hdpi\ic_launcher_foreground.png", $true, $false)
[IconGenerator]::Render(216, "D:\Newsly\android\app\src\main\res\mipmap-xhdpi\ic_launcher_foreground.png", $true, $false)
[IconGenerator]::Render(324, "D:\Newsly\android\app\src\main\res\mipmap-xxhdpi\ic_launcher_foreground.png", $true, $false)
[IconGenerator]::Render(432, "D:\Newsly\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher_foreground.png", $true, $false)

Write-Output "Generating iOS AppIcon assets..."
$iosPath = "D:\Newsly\ios\Runner\Assets.xcassets\AppIcon.appiconset"
[IconGenerator]::Render(20,   "$iosPath\Icon-App-20x20@1x.png", $false, $false)
[IconGenerator]::Render(40,   "$iosPath\Icon-App-20x20@2x.png", $false, $false)
[IconGenerator]::Render(60,   "$iosPath\Icon-App-20x20@3x.png", $false, $false)
[IconGenerator]::Render(29,   "$iosPath\Icon-App-29x29@1x.png", $false, $false)
[IconGenerator]::Render(58,   "$iosPath\Icon-App-29x29@2x.png", $false, $false)
[IconGenerator]::Render(87,   "$iosPath\Icon-App-29x29@3x.png", $false, $false)
[IconGenerator]::Render(40,   "$iosPath\Icon-App-40x40@1x.png", $false, $false)
[IconGenerator]::Render(80,   "$iosPath\Icon-App-40x40@2x.png", $false, $false)
[IconGenerator]::Render(120,  "$iosPath\Icon-App-40x40@3x.png", $false, $false)
[IconGenerator]::Render(120,  "$iosPath\Icon-App-60x60@2x.png", $false, $false)
[IconGenerator]::Render(180,  "$iosPath\Icon-App-60x60@3x.png", $false, $false)
[IconGenerator]::Render(76,   "$iosPath\Icon-App-76x76@1x.png", $false, $false)
[IconGenerator]::Render(152,  "$iosPath\Icon-App-76x76@2x.png", $false, $false)
[IconGenerator]::Render(167,  "$iosPath\Icon-App-83.5x83.5@2x.png", $false, $false)
[IconGenerator]::Render(1024, "$iosPath\Icon-App-1024x1024@1x.png", $false, $false)

Write-Output "All icons generated successfully!"
