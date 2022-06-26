//
//  ContentView.swift
//  MK Downloader
//
//  Created by Maheep Kumar Kathuria on 24/06/22.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var downloads: FetchedResults<Download>
    
    @State var downloadAddRequested: Bool = false
    
    var body: some View {
        NavigationView {
            DownloadsView()
                .navigationTitle("Downloads")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            downloadAddRequested = true
                        } label: {
                            Label("New", systemImage: "plus.square.on.square").labelStyle(AdaptiveLabelStyle())
                        }.sheet(isPresented: $downloadAddRequested) {
                            NavigationView {
                                DownloadDetailsView(isOpen: $downloadAddRequested)
                                    .navigationTitle("Add Download")
                            }
                        }
                    }
                }
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
