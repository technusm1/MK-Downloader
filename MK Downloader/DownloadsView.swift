//
//  DownloadsView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 24/06/22.
//

import SwiftUI

struct DownloadsView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var downloads: FetchedResults<Download>
    
    @State var isSheetPresented: Bool = false
    
    func deleteDownloads(at offsets: IndexSet) {
        for offset in offsets {
            let download = downloads[offset] // find this book in our fetch request
            moc.delete(download) // delete it from the context
        }
        
        // save the context
        try? moc.save()
    }
    
    var body: some View {
        List {
            ForEach(downloads) { download in
                DownloadItem(isSheetPresented: $isSheetPresented, item: download)
                    //.sheet(isPresented: $isSheetPresented) {}
            }.onDelete(perform: deleteDownloads)
//            .buttonStyle(BorderlessButtonStyle())
            // This button style needs to be set because Apple is infinitely wise: https://developer.apple.com/forums/thread/119541?answerId=394370022#394370022
        }
    }
}

struct AdaptiveLabelStyle: LabelStyle {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func makeBody(configuration: Configuration) -> some View {
        if horizontalSizeClass == .compact {
            configuration.icon
        } else {
            configuration.title
        }
    }
}

struct DownloadItem: View {
    @Binding var isSheetPresented: Bool
    @AppStorage("downloadURLsInErrorState") var errorDownloads: Set<String> = Set([])
    @AppStorage("downloadURLsPaused") var pausedDownloads: Set<String> = Set([])
    
    @State var downloadAmount: Double = 0
    @State var totalDownloadSize: Double = 100
    @State var item: Download
    
    var body: some View {
        HStack {
            if let downloadURL = item.url, errorDownloads.contains(downloadURL.absoluteString) {
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .foregroundColor(.red)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                    .frame(width: 48, height: 48, alignment: .center)
            } else if let data = item.siteFavicon, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .clipShape(Circle())
                    .shadow(radius: 2)
                    .frame(width: 48, height: 48, alignment: .center)
            } else {
                Image(systemName: "arrow.down.circle")
                    .resizable()
                    .foregroundColor(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                    .frame(width: 48, height: 48, alignment: .center)
            }
            ZStack {
                VStack {
                    HStack {
                        Text("\(item.filename ?? "<Unknown>")").font(.title3).bold()
                        Spacer()
                    }
                    HStack {
                        ProgressView(value: downloadAmount, total: totalDownloadSize) {
                            Label("10.58 MB / 100.78 GB", systemImage: "tray.and.arrow.down").font(.footnote)
                        }
                        Spacer()
                    }.padding(.horizontal, 0)
                    .padding(.bottom, 1)
                    HStack(spacing: 2) {
                        Label("113.5 MB/s", systemImage: "arrow.down.circle").font(.footnote)
                        Label("59:04:01", systemImage: "clock").font(.footnote)
                        Spacer()
                    }.padding(.horizontal, 0)
                }
                Button {
                    isSheetPresented = true
                } label: {
                    Label("Advanced", systemImage: "gearshape.2").labelStyle(IconOnlyLabelStyle())
                        .sheet(isPresented: $isSheetPresented) {
                            NavigationView {
                                DownloadDetailsView(isOpen: $isSheetPresented, downloadURL: item.url?.absoluteString ?? "", destinationFileName: item.filename ?? "", image: item.siteFavicon != nil ? UIImage(data: item.siteFavicon!) : nil)
                                    .navigationTitle("Download Details")
                            }
                        }
                }.opacity(0)
                // The above is a very ugly hack to get ListView items and buttons working in harmony.
            }
            Label("Pause/Resume", systemImage: pausedDownloads.contains(item.url?.absoluteString ?? "") ? "play.fill" : "pause.fill").labelStyle(IconOnlyLabelStyle())
                .onTapGesture {
                    var downloadTask: Task<Void, Error>? = nil
                    print(pausedDownloads)
                    // Download is currently paused, need to resume
                    if pausedDownloads.contains(item.url!.absoluteString) {
                        pausedDownloads.remove(item.url!.absoluteString)
                        let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
                        let destination = documentsDir.appendingPathComponent(item.url!.lastPathComponent)
                        print(destination)
                        guard let downloadUrl = item.url else { return }
                        let request = URLRequest(url: downloadUrl)
                        
                        downloadTask = Task {
                            print("Task launched")
                            let bufferSize = 65_536
                            let estimatedSize: Int64 = 1_000_000
                            // Based on guidance from: https://khanlou.com/2021/10/download-progress-with-awaited-network-tasks/
                            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                            // note, if server cannot provide expectedContentLength, this will be -1
                            let expectedLength = response.expectedContentLength
                            DispatchQueue.main.async {
                                totalDownloadSize = Double(expectedLength > 0 ? expectedLength : estimatedSize)
                            }
                            
                            guard let output = OutputStream(url: destination, append: false) else {
                                throw URLError(.cannotOpenFile)
                            }
                            output.open()

                            var buffer = Data()
                            if expectedLength > 0 {
                                buffer.reserveCapacity(min(bufferSize, Int(expectedLength)))
                            } else {
                                buffer.reserveCapacity(bufferSize)
                            }
                            
                            var count: Int64 = 0
                            for try await byte in asyncBytes {
                                try Task.checkCancellation()

                                count += 1
                                buffer.append(byte)

                                if buffer.count >= bufferSize {
                                    try output.write(buffer)
                                    buffer.removeAll(keepingCapacity: true)

                                    if expectedLength < 0 || count > expectedLength {
                                        totalDownloadSize = Double(count + estimatedSize)
                                    }
                                    downloadAmount = Double(count)
                                }
                            }

                            if !buffer.isEmpty {
                                try output.write(buffer)
                            }

                            output.close()

                            totalDownloadSize = Double(count)
                            downloadAmount = Double(count)
                        }
                    } else {
                        pausedDownloads.insert(item.url!.absoluteString)
                        downloadTask?.cancel()
                    }
                }
                .padding(.trailing, 2)
        }
        //.listRowBackground([true, false].randomElement()! ? Color.red.opacity(0.2) : nil)
    }
}

struct DownloadsView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsView()
    }
}
