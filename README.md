# Youtube Downloader Flutter

This is a cross platform app (currently tested on Android, Windows and Linux) to download videos from YouTube, it's still a WIP. It is mostly e remake of [YoutubeDownloader](https://github.com/Tyrrrz/YoutubeDownloader).
You can search a video from YouTube (within the app) and chose which stream you'd like to download.
If FFMPEG is added to the path you can long-press two tiles (audio and video), and those tracks will be merged into one, remember that muxed tracks (the ones with already audio + video, have a poor quality).

## Building the app

You must have the flutter sdk installed.

First clone the app into your system:
`git clone https://github.com/Hexer10/youtube_downloader_flutter.git`

Then from inside the project directory run:
`flutter build <windows/apk/linux>`

Then locate and run the app (ie in windows it is located inside build\windows\runner\Release).

## Todos / Known issues
 - [x] Directory finder inside settings doesn't work in MacOS/Linux. ([#7](https://github.com/Hexer10/youtube_downloader_flutter/issues/7)).
 - [x] Show notification when a file is being downloaded/has finished downloading ([#9](https://github.com/Hexer10/youtube_downloader_flutter/issues/9)).
 - [ ] Implement GitHub Actions and upload the binaries as artifacts ([#6](https://github.com/Hexer10/youtube_downloader_flutter/issues/6)).
 - [x] Implement `flutter_ffmpeg` for IOS/Android ([#8](https://github.com/Hexer10/youtube_downloader_flutter/issues/8))
 - [ ] Parse playlists / channel uploads.
## Screenshots

<img width="288" alt="HomePage" src="https://user-images.githubusercontent.com/21113203/113563902-c7beb100-9608-11eb-845a-4bad383d2e6b.PNG">
<img width="440" alt="Settings" src="https://user-images.githubusercontent.com/21113203/113563973-df963500-9608-11eb-9583-0031dcd92d76.PNG">
<img width="637" alt="SearchBig" src="https://user-images.githubusercontent.com/21113203/113563918-cbeace80-9608-11eb-8e26-ba4212cccd9d.PNG">
<img width="286" alt="SearchSmall" src="https://user-images.githubusercontent.com/21113203/113563926-cee5bf00-9608-11eb-950f-4934906554b9.PNG">
<img width="659" alt="StreamList Merge" src="https://user-images.githubusercontent.com/21113203/113563992-e45ae900-9608-11eb-8bb5-6787fd0c3e86.PNG"><img width="666" alt="Downloads" src="https://user-images.githubusercontent.com/21113203/113564014-ecb32400-9608-11eb-9a69-1aa5a0655217.PNG">


