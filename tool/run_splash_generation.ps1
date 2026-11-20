$ErrorActionPreference = "Stop"

Add-Type -Path "d:\Newsly\tool\IconGenerator.cs" -ReferencedAssemblies System.Drawing

Write-Host "Rendering iOS Launch Images (96pt native, 25% smaller)..."
[IconGenerator]::RenderSplash(96,  "d:\Newsly\ios\Runner\Assets.xcassets\LaunchImage.imageset\LaunchImage.png", 1.0)
[IconGenerator]::RenderSplash(192, "d:\Newsly\ios\Runner\Assets.xcassets\LaunchImage.imageset\LaunchImage@2x.png", 1.0)
[IconGenerator]::RenderSplash(288, "d:\Newsly\ios\Runner\Assets.xcassets\LaunchImage.imageset\LaunchImage@3x.png", 1.0)

Write-Host "Rendering Android Pre-API 31 Splash Drawables (25% smaller with transparent padding)..."
[IconGenerator]::RenderSplash(256, "d:\Newsly\android\app\src\main\res\drawable\splash_icon.png", 0.75)
[IconGenerator]::RenderSplash(128, "d:\Newsly\android\app\src\main\res\drawable-mdpi\splash_icon.png", 0.75)
[IconGenerator]::RenderSplash(192, "d:\Newsly\android\app\src\main\res\drawable-hdpi\splash_icon.png", 0.75)
[IconGenerator]::RenderSplash(256, "d:\Newsly\android\app\src\main\res\drawable-xhdpi\splash_icon.png", 0.75)
[IconGenerator]::RenderSplash(384, "d:\Newsly\android\app\src\main\res\drawable-xxhdpi\splash_icon.png", 0.75)
[IconGenerator]::RenderSplash(512, "d:\Newsly\android\app\src\main\res\drawable-xxxhdpi\splash_icon.png", 0.75)

Write-Host "Rendering Android 12+ Adaptive Splash Foreground Icons (0.525 scale, 25% smaller in safe zone)..."
[IconGenerator]::RenderSplash(108, "d:\Newsly\android\app\src\main\res\drawable-mdpi\ic_splash_foreground.png", 0.525)
[IconGenerator]::RenderSplash(162, "d:\Newsly\android\app\src\main\res\drawable-hdpi\ic_splash_foreground.png", 0.525)
[IconGenerator]::RenderSplash(216, "d:\Newsly\android\app\src\main\res\drawable-xhdpi\ic_splash_foreground.png", 0.525)
[IconGenerator]::RenderSplash(324, "d:\Newsly\android\app\src\main\res\drawable-xxhdpi\ic_splash_foreground.png", 0.525)
[IconGenerator]::RenderSplash(432, "d:\Newsly\android\app\src\main\res\drawable-xxxhdpi\ic_splash_foreground.png", 0.525)

Write-Host "All Splash assets generated successfully!"
