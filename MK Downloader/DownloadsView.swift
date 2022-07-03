//
//  DownloadsView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 24/06/22.
//

import SwiftUI

struct DownloadsView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @FetchRequest(sortDescriptors: []) var downloads: FetchedResults<Download>
    @State var downloadStateDict: [String : DownloadManager.DownloadStatus] = [:]

    @State var isSheetPresented: Bool = false
    
    func deleteDownloads(at offsets: IndexSet) {
        for offset in offsets {
            let download = downloads[offset] // find this book in our fetch request
            DownloadManager.shared.removeDownload(download)
            downloadStateDict.removeValue(forKey: download.url!.absoluteString)
        }
    }
    
    var body: some View {
        List {
            ForEach(downloads) { download in
                DownloadItem(item: download, currentDownloadStatus: Binding<DownloadManager.DownloadStatus>(get: {
                    if let downloadStatusValue = downloadStateDict[download.url!.absoluteString] {
                        return downloadStatusValue
                    }
                    return .invalid
                }, set: { newValue in
                    downloadStateDict[download.url!.absoluteString] = newValue
                }))
            }.onDelete(perform: deleteDownloads)
        }.sheet(isPresented: self.$isSheetPresented) {
            NavigationView {
                DownloadDetailsView(isOpen: self.$isSheetPresented, addMode: true)
                    .navigationTitle("Add Download")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isSheetPresented = true
                } label: {
                    Label("New", systemImage: "plus.square.on.square").labelStyle(AdaptiveLabelStyle())
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .compact {
                    Menu(content: {
                        Button("Pause all", action: {
                            for i in downloadStateDict.keys {
                                if downloadStateDict[i] != .completed {
                                    downloadStateDict[i] = .paused
                                }
                            }
                        })
                        Button("Resume all", action: {
                            for i in downloadStateDict.keys {
                                downloadStateDict[i] = .running
                            }
                        })
                        Button("Clear completed", action: {
                            let removalSet = Set(
                                downloadStateDict.compactMap { (key: String, value: DownloadManager.DownloadStatus) in
                                return value == .completed ? key : nil
                            })
                            downloads.filter { download in
                                removalSet.contains(download.url!.absoluteString)
                            }.forEach { download in
                                downloadStateDict.removeValue(forKey: download.url!.absoluteString)
                                DownloadManager.shared.removeDownload(download)
                            }
                        })
                        
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                } else {
                    Button("Pause all", action: {
                        for i in downloadStateDict.keys {
                            if downloadStateDict[i] != .completed {
                                downloadStateDict[i] = .paused
                            }
                        }
                    })
                    Button("Resume all", action: {
                        for i in downloadStateDict.keys {
                            downloadStateDict[i] = .running
                        }
                    })
                    Button("Clear completed", action: {
                        let removalSet = Set(
                            downloadStateDict.compactMap { (key: String, value: DownloadManager.DownloadStatus) in
                            return value == .completed ? key : nil
                        })
                        downloads.filter { download in
                            removalSet.contains(download.url!.absoluteString)
                        }.forEach { download in
                            DownloadManager.shared.removeDownload(download)
                            downloadStateDict.removeValue(forKey: download.url!.absoluteString)
                        }
                    })
                }
            }
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
    @State var isSheetPresented: Bool = false
    
    @State var downloadAmount: Double = 0
    @State var totalDownloadSize: Double = 0
    @State var downloadSpeed: Int64 = 0
    @State var lastDownloadAmount: Double = 0
    @State var lastTime = DispatchTime.now()
    @State var item: Download
    @State var canUpdateDownloadProgress: Bool = true
    
    @Binding var currentDownloadStatus: DownloadManager.DownloadStatus
    
    private func updateDownloadProgress(currentlyDownloaded: Double?, totalDownloadSize: Double?) {
        if let currentlyDownloaded = currentlyDownloaded {
            self.downloadAmount = currentlyDownloaded
            downloadSpeed = Int64((currentlyDownloaded - lastDownloadAmount) / Double(DispatchTime.now().uptimeNanoseconds - lastTime.uptimeNanoseconds) * 1_000_000_000.0)
            lastTime = DispatchTime.now()
            lastDownloadAmount = currentlyDownloaded
        }
        if let totalDownloadSize = totalDownloadSize {
            if totalDownloadSize >= lastDownloadAmount {
                self.totalDownloadSize = totalDownloadSize
            }
        }
        // The condition below is for when a particular download is complete.
        if let currentlyDownloaded = currentlyDownloaded, let totalDownloadSize = totalDownloadSize, (currentlyDownloaded == totalDownloadSize && currentlyDownloaded > 0) {
            currentDownloadStatus = .completed
            downloadSpeed = 0
        }
    }
    
    var body: some View {
        HStack {
            if let destinationFileName = item.filename {
                ZStack {
                    Group {
                        Image(uiImage: UIImage.icon(forFileNamed: destinationFileName, preferredSize: .largest))
                            .resizable()
                            .scaleEffect(0.5)
                            .scaledToFit()
                            .shadow(radius: 2)
                        if !totalDownloadSize.isZero && !downloadAmount.isEqual(to: totalDownloadSize) {
                            ProgressView(value: downloadAmount, total: totalDownloadSize).progressViewStyle(MKProgressViewStyle())
                        }
                    }.frame(width: 64, alignment: .leading)
                }
            }
            ZStack {
                VStack(alignment: .leading) {
                    Text("\(item.filename ?? "<Unknown>")").bold()
                    if !totalDownloadSize.isZero && !downloadAmount.isEqual(to: totalDownloadSize) {
                        HStack {
                            Text("\(Int64(downloadAmount).formatted(.byteCount(style: ByteCountFormatStyle.Style.memory, allowedUnits: .all, spellsOutZero: false, includesActualByteCount: false))) of \(Int64(totalDownloadSize).formatted(.byteCount(style: ByteCountFormatStyle.Style.memory, allowedUnits: .all, spellsOutZero: false, includesActualByteCount: false)))").font(.footnote)
                            Text("(\(downloadSpeed.formatted(.byteCount(style: ByteCountFormatStyle.Style.memory, allowedUnits: .all, spellsOutZero: false, includesActualByteCount: false)))/s)").font(.footnote)
                            Spacer()
                        }
                    } else if !downloadAmount.isZero || downloadAmount.isEqual(to: totalDownloadSize) {
                        HStack {
                            Text("\(Int64(downloadAmount).formatted(.byteCount(style: ByteCountFormatStyle.Style.memory, allowedUnits: .all, spellsOutZero: false, includesActualByteCount: false)))").font(.footnote)
                            Spacer()
                        }
                    }
                }
                Button {
                    isSheetPresented = true
                } label: {
                    Label("Advanced", systemImage: "gearshape.2").labelStyle(IconOnlyLabelStyle())
                        .sheet(isPresented: $isSheetPresented) {
                            NavigationView {
                                DownloadDetailsView(isOpen: $isSheetPresented, downloadURL: item.url?.absoluteString ?? "", destinationFileName: item.filename ?? "")
                                    .navigationTitle("Download Details")
                            }
                        }
                }.opacity(0)
                // The above is a very ugly hack to get ListView items and buttons working in harmony.
            }
            Label("Pause/Resume", systemImage: (currentDownloadStatus == .paused || currentDownloadStatus == .completed) ? "play.fill" : "pause.fill").labelStyle(IconOnlyLabelStyle())
                .onTapGesture {
                    print("On tap")
                    if currentDownloadStatus == .paused {
                        currentDownloadStatus = .running
                    } else if currentDownloadStatus == .running {
                        currentDownloadStatus = .paused
                    }
                }
                .onAppear(perform: {
                    print("On appear")
                    if let fileName = item.filename {
                        let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
                        let destination = documentsDir.appendingPathComponent(fileName)
                        let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
                        if fileSizeOnDisk > 0 {
                            downloadAmount = Double(fileSizeOnDisk)
                        }
                    }
                    // For setting the INITIAL STATE OF THE DOWNLOAD. IT SHOULD BE DONE FROM HERE.
                    if DownloadManager.shared.getStatusOfDownload(url: item.url) != .invalid {
                        currentDownloadStatus = DownloadManager.shared.getStatusOfDownload(url: item.url)
                    }
                    print(currentDownloadStatus)
                })
                .onChange(of: currentDownloadStatus, perform: { newValue in
                    print("On change \(item.url) \(downloadAmount) \(totalDownloadSize)")
                    if currentDownloadStatus == .running {
                        DownloadManager.shared.resumeDownload(url: item.url) { currentlyDownloaded, totalDownloadSize in
                            DispatchQueue.main.async {
                                updateDownloadProgress(currentlyDownloaded: currentlyDownloaded, totalDownloadSize: totalDownloadSize)
                            }
                        }
                    } else if currentDownloadStatus == .paused {
                        DownloadManager.shared.pauseDownload(url: item.url)
                    }
                })
                .padding(.trailing, 2)
        }
        //.listRowBackground([true, false].randomElement()! ? Color.red.opacity(0.2) : nil)
    }
}

struct MKProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 1.0)
                .opacity(0.3)
                .foregroundColor(Color.blue)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(configuration.fractionCompleted ?? 0, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.blue)
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}

//struct DownloadsView_Previews: PreviewProvider {
//    static var previews: some View {
//        DownloadsView()
//    }
//}

struct MKProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView.init(value: 64, total: 100).progressViewStyle(MKProgressViewStyle())
    }
}
