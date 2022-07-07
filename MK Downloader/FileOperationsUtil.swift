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
    
    // Based on this answer at StackOverflow: https://stackoverflow.com/a/56616990/4385319
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
            (0..<match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
        } ?? []
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
    
    static func getSizeofFile(atPath url: URL) -> Int64 {
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            if let bytes = fileAttributes[.size] as? Int64 {
                return bytes
            }
        }
        return -1
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
}
