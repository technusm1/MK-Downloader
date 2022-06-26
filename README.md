# MK-Downloader
Its much better to use this than downloading using Safari on iOS/iPadOS.

🔥 **This project has just barely begun, and has lot of buggy code inside at the moment, and is thus not suitable for general use. You've been warned.**

## Why this project?
This project exists, because Safari on iPadOS/iOS can't even resume downloads properly and I'm done experiencing that. While great command line tools like `curl` and `wget` that can do a much better job (albeit chaotically) on these platforms, they are quite limited. IMO, its much better to have a separate application. Benefits include:
- Background downloading (at least for HTTP/HTTPS).
- Drag and drop or read URLs from Clipboard and autostart downloads.
- Fancy features like curl globbing can be baked into the app, with proper UI. Though its gonna be a lot of coding.
- Learning Swift and SwiftUI.

## Compatibility
This app needs minimum iOS 15 to run as of now. I recommend having the latest general release of iOS/iPadOS running on your devices, since thats what I'm able to test against.
Currently, SwiftUI is a very unstable platform to develop on, since Apple keeps repeatingly changing/deprecating APIs and even changes API behaviors (in some cases, even across minor iOS versions).

## Available on App Store?
No plans for the App Store yet. App's not ready.
