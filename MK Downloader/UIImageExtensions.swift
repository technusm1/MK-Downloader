//
//  UIImageExtensions.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 28/06/22.
//  Full credits go to Daniel Jalkut for this blog post: https://indiestack.com/2018/05/icon-for-file-with-uikit/
//

import Foundation
import UIKit

extension UIImage {
    public enum FileIconSize {
        case smallest
        case largest
    }

    public class func icon(for fileURL: URL, preferredSize: FileIconSize = .smallest) -> UIImage {
        let myInteractionController = UIDocumentInteractionController(url: fileURL)
        let allIcons = myInteractionController.icons

        // allIcons is guaranteed to have at least one image
        switch preferredSize {
            case .smallest: return allIcons.first!
            case .largest: return allIcons.last!
        }
    }
    
    public class func icon(forFileNamed fileName: String, preferredSize: FileIconSize = .smallest) -> UIImage {
        return icon(for: URL(fileURLWithPath: fileName), preferredSize: preferredSize)
    }
}
