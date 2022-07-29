# MK-Downloader

🔥 **This project has just barely begun, and has lot of buggy code inside at the moment, and is thus not suitable for general use. You've been warned.**

## Why this project?
This project exists, because Safari on iPadOS/iOS can't even resume downloads properly and I'm done experiencing that. Good old command line tools like `curl` and `wget` can do a much better job, but on these platforms, they are quite limited, mainly due to the following reasons:
- Unlike desktop, typing commands on a touch screen device using on-screen keyboard is not a great experience, and I've yet to find a terminal UI properly designed for a touch screen, especially when it comes to moving the cursor and selecting the text here and there. It can be done, no doubt, but its not great.
- iOS can randomly suspend apps/put them in the background to conserve battery. Thus terminal emulators will be suspended and with them, the command(s) running inside them will be suspended as well.

Thus, its better to have a separate application thats friendly with a touch-based OS and has some, if not all the powers of the command-line tools. Some potential benefits:
- Background downloading support on iOS/iPadOS (at least for HTTP/HTTPS).
- Minor conveniences like Drag and drop URLs to program (its a good thing on the iPad), automatically reading URLs from Clipboard so user doesn't have to enter them, changing download details easily (like download URL, destination file name) and easily managing downloads.
- If properly coded, features like curl's URL globbing can be baked into the app, with proper UI.
- **JUST FOR ME**: Learning Swift and SwiftUI.

## Compatibility
This app needs minimum iOS 15 to run as of now. I recommend having the latest general release of iOS/iPadOS running on your devices, since thats what I'm able to test against.

## Available on App Store?
App's not ready yet. All in good time.
