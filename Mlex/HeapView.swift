//
//  HeapView.swift
//  viewtest
//
//  Created by Dora Orak on 27.01.2025.
//

import AppKit
import SwiftUI

struct HeapView: View {
    
    let ds: NSMutableDictionary
    @State var selectedClass: String?
        
    
    var body: some View {
        var sds = ds as! Dictionary<String, [Int]>
        
        VStack {
            HSplitView {
                // Left List: Displays the classes
                List(Array(sds.keys.sorted()), id: \.self, selection: $selectedClass) { key in
                    
                    Text(key)
                }
                .navigationTitle("Classes")
                .frame(minWidth: 150) // Adjust width of the left list
                
                // Right List: Displays the items of the selected class
                if let selectedClass, let items = sds[selectedClass] {
                    List(items, id: \.self) { item in
                        Text(String(item))
                    }
                    .navigationTitle(selectedClass)
                } else {
                    // Placeholder for when no class is selected
                    Text("Select a class")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}


@objc class HeapViewSwift: NSObject {
 
    @MainActor @objc class func createHeapViewController(_ ds: NSMutableDictionary) -> NSViewController {
        
        var view = HeapView(ds: ds)
       
        return NSHostingController(rootView: view)
    }
}
