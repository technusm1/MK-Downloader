//
//  DownloadDetailsView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 25/06/22.
//

import SwiftUI
import FaviconFinder

struct DownloadDetailsView: View {
    @Environment(\.managedObjectContext) var moc
    @Binding var isOpen: Bool
    
    @AppStorage("downloadURLsPaused") var pausedDownloads: Set<String> = Set([])
    
    @State var downloadURL: String = {
        // Privacy preserving way of doing things, and pasting only when we're guaranteed to be sure
        // Some gotchas here: https://developer.apple.com/forums/thread/654700?answerId=635786022#635786022
        return UIPasteboard.general.hasURLs ? UIPasteboard.general.string! : ""
    }()
    @State var destinationFileName: String = ""
    @State var isGlobbingAllowed: Bool = false
    @State var image: UIImage?
    
    func getFavicon() async {
        do {
            print("Running MK \(downloadURL)")
            if DownloadDetailsView.isURL(downloadURL) {
                let favicon = try await FaviconFinder(url: URL(string: downloadURL)!).downloadFavicon()
                DispatchQueue.main.async {
                    self.image = favicon.image
                }
            } else {
                self.image = nil
            }
            
        } catch {
            // nothing to do
        }
    }
    
    var body: some View {
        VStack {
            Form {
                Group {
                    if let image = image {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .clipShape(Circle())
                                .shadow(radius: 2)
                                .frame(width: 64, height: 64, alignment: .center)
                            Spacer()
                        }
                    } else {
                        EmptyView()
                            .frame(width: 64, height: 64, alignment: .center)
                    }
                }
                TextField("Destination file name\(DownloadDetailsView.isGlobbingPossible(for: downloadURL) && isGlobbingAllowed ? "(s)" : "")", text: $destinationFileName)
                    .disableAutocorrection(true)
                TextField("Download URL", text: $downloadURL)
                    .textContentType(.URL)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .onChange(of: downloadURL) { newValue in
                        if image == nil {
                            Task {
                                await getFavicon()
                            }
                        }
                    }
                    .onAppear {
                        if image == nil {
                            Task {
                                await getFavicon()
                            }
                        }
                    }
                if DownloadDetailsView.isGlobbingPossible(for: downloadURL) {
                    Toggle(isOn: $isGlobbingAllowed,
                           label: {
                               Text("Allow URL globbing")
                    })
                }
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isOpen = false
                } label: {
                    Label("Cancel", systemImage: "trash").labelStyle(TitleOnlyLabelStyle())
                }.tint(.red)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // save downloads
                    let download = Download(context: moc)
                    download.url = URL(string: downloadURL)
                    download.filename = destinationFileName
                    download.siteFavicon = image?.pngData()
                    try? moc.save()
                    pausedDownloads.insert(downloadURL)
                    isOpen = false
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down").labelStyle(AdaptiveLabelStyle())
                }
            }
        }
    }
    
    static func isGlobbingPossible(for url: String) -> Bool {
        return isURL(url)
    }
    
    static func isURL(_ urlString: String?) -> Bool {
        if let urlString = urlString {
            return urlString.isValidURL
        }
        return false
    }
}

struct DownloadDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadDetailsView(isOpen: .constant(true))
    }
}
