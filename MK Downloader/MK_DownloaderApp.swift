//
//  MK_DownloaderApp.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 24/06/22.
//

import SwiftUI

@main
struct MK_DownloaderApp: App {
    // Creating all this based on Paul Hudson's tutorial: https://www.hackingwithswift.com/books/ios-swiftui/how-to-combine-core-data-and-swiftui
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DownloadManager.moc)
        }
    }
}
