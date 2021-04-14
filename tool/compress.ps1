$loc = Get-Location
Set-Location 'build/windows/runner/Release'
$compress = @{
    LiteralPath = "../../../../LICENSE", "data/", "flutter_windows.dll", "url_launcher_windows_plugin.dll", "window_size_plugin.dll", "youtube_downloader_flutter.exe"
    DestinationPath = "Youtube Downloader.zip"

}
Compress-Archive -Force @compress
Move-Item -Path './Youtube Downloader.zip' -Destination '../../../../Youtube Downloader.zip'
Set-Location $loc