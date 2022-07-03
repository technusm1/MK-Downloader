//
//  DownloadDataController.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 25/06/22.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Download")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}

class DownloadManager {
    static let shared = DownloadManager()
    static let moc = DataController().container.viewContext
    
    var count: Int = 0
    var downloadsDict: [String : (status: DownloadStatus, associatedFile: String, downloadTask: Task<Void, Error>?)] = [:]
    
    init() {
        let request = NSFetchRequest<Download>(entityName: "Download")
        if let downloads = try? DownloadManager.moc.fetch(request) {
            for download in downloads {
                downloadsDict[download.url!.absoluteString] = (status: .paused, associatedFile: download.filename!, downloadTask: nil)
            }
            count = downloads.count
        }
    }
    
    enum DownloadStatus {
    case error, paused, running, invalid, completed
    }
    
    func addDownload(url: URL, destination destinationFileName: String?) {
        let downloadToSave = Download(context: DownloadManager.moc)
        downloadToSave.url = url
        downloadToSave.filename = destinationFileName ?? url.lastPathComponent
        downloadsDict[url.absoluteString] = (status: .running, associatedFile: downloadToSave.filename!, downloadTask: nil)
        count += 1
        try? DownloadManager.moc.save()
    }
    
    func getStatusOfDownload(url: URL?) -> DownloadStatus {
        if let downloadURL = url {
            if let downloadKey = downloadsDict[downloadURL.absoluteString] {
                return downloadKey.status
            }
        }
        return .invalid
    }
    
    func resumeDownload(url: URL?, progressCallbackFunc: ((_ currentlyDownloaded: Double?, _ totalDownloadSize: Double?) -> ())? = nil) {
        if let url = url {
            downloadsDict[url.absoluteString]?.status = .running
            downloadsDict[url.absoluteString]?.downloadTask = Task { () in
                print("Task launched")
                let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
                let destination = documentsDir.appendingPathComponent(downloadsDict[url.absoluteString]!.associatedFile)
                print(destination)
                var request = URLRequest(url: url)
                let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
                if fileSizeOnDisk > 0 {
                    request.setValue("bytes=\(fileSizeOnDisk)-", forHTTPHeaderField: "Range")
                    try await download(from: request, saveTo: destination, existingFileSize: Double(fileSizeOnDisk), progressCallbackFunc: progressCallbackFunc)
                } else {
                    try await download(from: request, saveTo: destination, progressCallbackFunc: progressCallbackFunc)
                }
                if !Task.isCancelled {
                    // Download is now complete
                    downloadsDict[url.absoluteString]?.status = .completed
                }
            }
        }
    }
    
    func pauseDownload(url: URL?) {
        if let url = url {
            downloadsDict[url.absoluteString]?.status = .paused
            downloadsDict[url.absoluteString]?.downloadTask?.cancel()
            downloadsDict[url.absoluteString]?.downloadTask = nil
        }
    }
    
    func modifyDownloadURL(from oldURL: URL, to newURL: URL) {}
    
    func removeDownload(_ download: Download) {
        if let url = download.url {
            downloadsDict.removeValue(forKey: url.absoluteString)
            DownloadManager.moc.delete(download)
            try? DownloadManager.moc.save()
            count -= 1
        }
    }
    
    private func download(from request: URLRequest, saveTo destination: URL, existingFileSize: Double = 0.0, progressCallbackFunc: ((_ currentlyDownloaded: Double?, _ totalDownloadSize: Double?) -> ())? = nil) async throws {
        let bufferSize = 65_536
        let estimatedSize: Int64 = 1_000_000
        // Based on guidance from: https://khanlou.com/2021/10/download-progress-with-awaited-network-tasks/
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        // note, if server cannot provide expectedContentLength, this will be -1
        let expectedLength = max(response.expectedContentLength, 0)
        print("Expected length: \(expectedLength)")
        // totalDownloadSize = Double(expectedLength > 0 ? expectedLength : estimatedSize)
        progressCallbackFunc?(existingFileSize, existingFileSize + Double(expectedLength >= 0 ? expectedLength : estimatedSize))
        
        if let httpResponse = response as? HTTPURLResponse {
            // if http response status code is client or server error
            // Refer: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
            if (400...599).contains(httpResponse.statusCode) {
                return
            }
        }
        
        guard let output = OutputStream(url: destination, append: true) else {
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
            do {
                try Task.checkCancellation()
            } catch {
                break
            }
            count += 1
            buffer.append(byte)

            if buffer.count >= bufferSize {
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength < 0 || count > expectedLength {
                    // totalDownloadSize = Double(count + estimatedSize)
                    progressCallbackFunc?(nil, existingFileSize + Double(count + estimatedSize))
                }
                // downloadAmount = Double(count)
                progressCallbackFunc?(existingFileSize + Double(count), nil)
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()
        if Task.isCancelled {
            return
        }
        // totalDownloadSize = Double(count)
        // downloadAmount = Double(count)
        progressCallbackFunc?(existingFileSize + Double(count), existingFileSize + Double(count))
    }
}
