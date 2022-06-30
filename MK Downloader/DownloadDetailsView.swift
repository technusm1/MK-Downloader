//
//  DownloadDetailsView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 25/06/22.
//

import SwiftUI

struct DownloadDetailsView: View {
    @Binding var isOpen: Bool
    @State var addMode: Bool = false
    
    @State var downloadURL: String = {
        // Privacy preserving way of doing things, and pasting only when we're guaranteed to be sure
        // Some gotchas here: https://developer.apple.com/forums/thread/654700?answerId=635786022#635786022
        return UIPasteboard.general.hasURLs ? UIPasteboard.general.string! : ""
    }()
    @State var destinationFileName: String = ""
    @State var isGlobbingAllowed: Bool = false
    
    var body: some View {
        VStack {
            Form {
                TextField("Destination file name\(DownloadDetailsView.isGlobbingPossible(for: downloadURL) && isGlobbingAllowed ? "(s)" : "")", text: $destinationFileName)
                    .disableAutocorrection(true)
                TextField("Download URL", text: $downloadURL)
                    .textContentType(.URL)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
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
                    if downloadURL.isValidURL {
                        if addMode {
                            print(downloadURL)
                            DownloadManager.shared.addDownload(url: URL(string: downloadURL)!, destination: (destinationFileName.isEmpty ? URL(string: downloadURL)!.lastPathComponent : destinationFileName))
                        }
                        isOpen = false
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down").labelStyle(AdaptiveLabelStyle())
                }
            }
        }
    }
    
    static func isGlobbingPossible(for url: String) -> Bool {
        return url.isValidURL
    }
}

struct DownloadDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadDetailsView(isOpen: .constant(true))
    }
}
