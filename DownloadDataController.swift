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
