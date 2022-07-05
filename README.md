# MK-Downloader

🔥 **This project has just barely begun, and has lot of buggy code inside at the moment, and is thus not suitable for general use. You've been warned.**

## Why this project?
This project exists, because Safari on iPadOS/iOS can't even resume downloads properly and I'm done experiencing that. While great command line tools like `curl` and `wget` can do a much better job (albeit chaotically) on these platforms, they are quite limited as well, because:
- Typing on a touch screen using on-screen keyboard is not a great experience, and terminal UI is not properly designed for a touch screen, especially when it comes to moving the cursor and selecting the text here and there. It can be done, no doubt, but its not great.
- iOS can randomly suspend apps/put them in the background to conserve battery. Thus terminal emulators will be suspended and with them, the command(s) running inside them will be suspended as well.

Thus, its much better to have a separate application thats a careful balance of both these approaches. Benefits include:
- Background downloading (at least for HTTP/HTTPS).
- Minor conveniences like Drag and drop, reading URLs from Clipboard so user doesn't have to enter them, changing download details easily (like download URL, destination file name) and easily managing downloads.
- Fancy features like curl's URL globbing can be baked into the app, with proper UI. Though its gonna be a lot of coding.
- Learning Swift and SwiftUI.

## Compatibility
This app needs minimum iOS 15 to run as of now. I recommend having the latest general release of iOS/iPadOS running on your devices, since thats what I'm able to test against.
Currently, SwiftUI is a very unstable platform to develop on, since Apple keeps repeatingly changing/deprecating APIs and even changes API behaviors (in some cases, even across minor iOS versions).

## Available on App Store?
App's not ready yet. All in good time.
