import AppKit
import SwiftUI

struct HeapView: View {
    
    @State var ds: NSMutableDictionary
    @State var selectedClass: String?
    @State var selectedInstance: String?
    @State var refreshHack: Bool = false
    
    
    var body: some View {
        let sds = ds as! Dictionary<String, [String]>
        
        HStack {
            Button("Refresh") {
                NotificationCenter.default.post(name: Notification.Name("MxRescanHeapNotification"), object: nil)
                selectedInstance = nil
                selectedClass = nil
            }
            Spacer()
        }
        
        HSplitView {
            // Left Column: Classes
            VStack(alignment: .leading) {
                Text("Classes (\(sds.keys.count))")
                    .font(.headline)
                    .padding(.leading)
                
                List(Array(sds.keys.sorted()), id: \.self, selection: $selectedClass) { key in
                    Text(key)
                }
                .frame(minWidth: 150) // Adjust width of the left list
            }
            
            // Middle Column: Instances
            VStack(alignment: .leading) {
                Text("Instances")
                    .font(.headline)
                    .padding(.leading)
                
                if let selectedClass, let insarr = sds[selectedClass] {
                    List(insarr.sorted(), id: \.self, selection: $selectedInstance) { ins in
                        Text(ins)
                    }
                    .navigationTitle(selectedClass)
                } else {
                    Text("Select a class")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            // Right Column: Instance Details
            VStack(alignment: .leading) {
                Text("Details")
                    .font(.headline)
                    .padding(.leading)
                
                if let selectedInstance {
                    InstanceDetailView(addr: selectedInstance as NSString)
                } else {
                    Text("Select an instance")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(minWidth: 300, minHeight: 200) // Adjust width and height of the whole view
        .padding()
    }
}




@objc class HeapViewSwift: NSObject {
 
    @MainActor @objc class func createHeapView(_ ds: NSMutableDictionary) -> NSView {
        
        let view = HeapView(ds: ds)
       
        return NSHostingView(rootView: view)
    }
}

