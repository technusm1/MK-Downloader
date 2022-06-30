//
//  ContentView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 24/06/22.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            DownloadsView()
                .navigationTitle("Downloads")
        }
        .navigationViewStyle(.stack)
        .tint(.accentColor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
