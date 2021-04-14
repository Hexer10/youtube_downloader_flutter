$loc = Get-Location
Set-Location 'build/windows/runner/Release'
$compress = @{
    LiteralPath = "../../../../LICENSE", "data/", "flutter_windows.dll", "url_launcher_windows_plugin.dll", "window_size_plugin.dll", "youtube_downloader_flutter.exe"
    DestinationPath = "Flutter Downloader.zip"

}
Compress-Archive -Force @compress
Move-Item -Path './Flutter Downloader.zip' -Destination '../../../../Flutter Downloader.zip'
Set-Location $loc