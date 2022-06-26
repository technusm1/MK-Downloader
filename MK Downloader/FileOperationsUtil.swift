//
//  FileOperationsUtil.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 25/06/22.
//

import Foundation

extension Set: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Set<Element>.self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return Set<Element>().rawValue
        }
        return result
    }
}

extension String {

    var isValidURL: Bool {
        guard !contains("..") else { return false }
    
        let head     = "((http|https)://)?([(w|W)]{3}+\\.)?"
        let tail     = "\\.+[A-Za-z]{2,3}+(\\.)?+(/(.)*)?"
        let urlRegEx = head+"+(.)+"+tail
    
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)

        return urlTest.evaluate(with: trimmingCharacters(in: .whitespaces))
    }

}

extension URLSession {
    func download(from url: URL, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        try await download(for: URLRequest(url: url), progress: parent)
    }

    func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        let progress = Progress()
        parent.addChild(progress, withPendingUnitCount: 1)

        let bufferSize = 65_536
        let estimatedSize: Int64 = 1_000_000

        let (asyncBytes, response) = try await bytes(for: request, delegate: delegate)
        let expectedLength = response.expectedContentLength                             // note, if server cannot provide expectedContentLength, this will be -1
        progress.totalUnitCount = expectedLength > 0 ? expectedLength : estimatedSize

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        guard let output = OutputStream(url: fileURL, append: false) else {
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
                    progress.totalUnitCount = count + estimatedSize
                }
                progress.completedUnitCount = count
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()

        progress.totalUnitCount = count
        progress.completedUnitCount = count

        return (fileURL, response)
    }
}

extension OutputStream {
    enum OutputStreamError: Error {
        case stringConversionFailure
        case bufferFailure
        case writeFailure
    }

    /// Write `Data` to `OutputStream`
    ///
    /// - parameter data:                  The `Data` to write.

    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw OutputStreamError.bufferFailure
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    throw OutputStreamError.writeFailure
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}

struct FileOperationsUtil {
    static func getApplicationDocumentsDirectory() -> URL {
        if let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return path
        }
        return URL(string: "")!
    }
    
    static func deleteFiles(in path: URL) {
        let documentsUrl =  getApplicationDocumentsDirectory()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
    }
    
    static func listAllFilesInDocumentsDirectory() {
        let documentsUrl =  getApplicationDocumentsDirectory()
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
        print(fileURLs)
    }
    
    static func writeDummyFileToDocumentsDirectory() {
        let name = "Maheep-Intro.txt"
        let documentsUrl =  getApplicationDocumentsDirectory()
        let fileURL = documentsUrl.appendingPathComponent(name)
        let myString = "My name is Maheep Kumar and I'm trying to write a file in iOS / iPadOS"
        if let strData = myString.data(using: .utf8) {
            try! strData.write(to: fileURL)
        }
    }
}
