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

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    static let shared = DownloadManager()
    static let moc = DataController().container.viewContext
    
    var count: Int = 0
    var downloadsDict: [String : (status: DownloadStatus, associatedFile: String, downloadTask: URLSessionDownloadTask?, progressCallbackFunc: ((_ currentlyDownloaded: Double?, _ totalDownloadSize: Double?) -> ())?)] = [:]
    lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    override init() {
        super.init()
        let request = NSFetchRequest<Download>(entityName: "Download")
        if let downloads = try? DownloadManager.moc.fetch(request) {
            for download in downloads {
                downloadsDict[download.url!.absoluteString] = (status: .paused, associatedFile: download.filename!, downloadTask: nil, progressCallbackFunc: nil)
            }
            count = downloads.count
        }
    }
    
    enum DownloadStatus {
    case error, paused, running, invalid, completed
    }
    
    func addDownload(url: URL, destination destinationFileName: String?) {
        if downloadsDict[url.absoluteString] != nil {
            // if downloadsDict already has a download by the name of the URL
            return
        }
        let downloadToSave = Download(context: DownloadManager.moc)
        downloadToSave.url = url
        downloadToSave.filename = destinationFileName ?? url.lastPathComponent
        downloadsDict[url.absoluteString] = (status: .running, associatedFile: downloadToSave.filename!, downloadTask: nil, progressCallbackFunc: nil)
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
            let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
            let destination = documentsDir.appendingPathComponent(downloadsDict[url.absoluteString]!.associatedFile)
            print(destination)
            var request = URLRequest(url: url)
            let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
            if fileSizeOnDisk > 0 {
                request.setValue("bytes=\(fileSizeOnDisk)-", forHTTPHeaderField: "Range")
            }
            downloadsDict[url.absoluteString]?.progressCallbackFunc = progressCallbackFunc
            downloadsDict[url.absoluteString]?.downloadTask = urlSession.downloadTask(with: request)
            downloadsDict[url.absoluteString]?.downloadTask?.resume()
        }
    }
    
    func pauseDownload(url: URL?) {
        if let url = url {
            downloadsDict[url.absoluteString]?.status = .paused
            downloadsDict[url.absoluteString]?.downloadTask?.cancel(byProducingResumeData: { data in
                // This variant of cancel needs to be called, as it produces resumeData, which is later used in the delegate error callback
                return
            })
            downloadsDict[url.absoluteString]?.downloadTask = nil
        }
    }
    
    func modifyDownloadURL(from oldURL: URL, to newURL: URL) {}
    
    func removeDownload(_ download: Download) {
        if let url = download.url {
            pauseDownload(url: url)
            downloadsDict.removeValue(forKey: url.absoluteString)
            DownloadManager.moc.delete(download)
            try? DownloadManager.moc.save()
            count -= 1
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
        let destination = documentsDir.appendingPathComponent(self.downloadsDict[downloadTask.originalRequest!.url!.absoluteString]!.associatedFile)
        let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
        if totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown {
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(totalBytesWritten), Double(fileSizeOnDisk))
        } else if fileSizeOnDisk >= 0 && totalBytesWritten <= totalBytesExpectedToWrite {
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(fileSizeOnDisk + totalBytesWritten), Double(fileSizeOnDisk + totalBytesExpectedToWrite))
        } else if totalBytesWritten <= totalBytesExpectedToWrite {
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(totalBytesWritten), Double(totalBytesExpectedToWrite))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Download completed with an error
        guard let error = error else {
            return
        }
        guard let httpResponse = task.response as? HTTPURLResponse else {
            return
        }
        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            guard let tempSearchStr: String = String(data: resumeData, encoding: String.Encoding.ascii) else { return }
            let result = tempSearchStr.match("CFNetworkDownload_([a-zA-z0-9])+.tmp")
            // we need the first and the only match
            let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(result[0][0])
            let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
            let destination = documentsDir.appendingPathComponent(self.downloadsDict[task.originalRequest!.url!.absoluteString]!.associatedFile)
            let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
            if fileSizeOnDisk < 0 && !(400...599).contains(httpResponse.statusCode) {
                // if file doesn't exist, replace the file
                try! FileManager.default.moveItem(at: tempFileURL, to: destination)
            } else if !(400...599).contains(httpResponse.statusCode) {
                // append to file
                guard let output = OutputStream(url: destination, append: true) else { return }
                output.open()
                let buffer = try! Data(contentsOf: tempFileURL)
                try? output.write(buffer)
                output.close()
                try? FileManager.default.removeItem(at: tempFileURL)
            } else {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Download finished successfully
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else {
            return
        }
        guard let url = downloadTask.originalRequest?.url else { return }
        let documentsDir = FileOperationsUtil.getApplicationDocumentsDirectory()
        let destination = documentsDir.appendingPathComponent(self.downloadsDict[url.absoluteString]!.associatedFile)
        let fileSizeOnDisk = FileOperationsUtil.getSizeofFile(atPath: destination)
        if fileSizeOnDisk < 0 && !(400...599).contains(httpResponse.statusCode) {
            // if file doesn't exist, replace the file
            try! FileManager.default.moveItem(at: location, to: destination)
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(FileOperationsUtil.getSizeofFile(atPath: destination)), Double(FileOperationsUtil.getSizeofFile(atPath: destination)))
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.status = .completed
        } else if !(400...599).contains(httpResponse.statusCode) {
            // append to file
            guard let output = OutputStream(url: destination, append: true) else { return }
            output.open()
            let buffer = try! Data(contentsOf: location)
            try? output.write(buffer)
            output.close()
            try? FileManager.default.removeItem(at: location)
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(FileOperationsUtil.getSizeofFile(atPath: destination)), Double(FileOperationsUtil.getSizeofFile(atPath: destination)))
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.status = .completed
        } else {
            try? FileManager.default.removeItem(at: location)
            self.downloadsDict[(downloadTask.originalRequest?.url!.absoluteString)!]?.progressCallbackFunc?(Double(FileOperationsUtil.getSizeofFile(atPath: destination)), Double(FileOperationsUtil.getSizeofFile(atPath: destination)))
        }
        print(destination)
    }
}
