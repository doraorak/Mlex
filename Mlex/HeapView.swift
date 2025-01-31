import AppKit
import SwiftUI

struct HeapView: View {
    
    let mx: Mlex = Mlex.sharedInstance()
    
    @State var selectedClass: String?
    @State var selectedInstance: String?
    @State private var data: [String: [String]] = [:]
    
    var body: some View {
        
        
        HStack {
            Button {
                mx.mxScanHeap()
                selectedInstance = nil
                selectedClass = nil
                data = mx.mxFoundHeapObjects as! [String : [String]]
            } label: {
                Text("Refresh");
            }
            Spacer()
        }
        
        HSplitView {
            // Left Column: Classes
            VStack(alignment: .leading) {
                Text("Classes (\(data.keys.count))")
                    .font(.headline)
                    .padding(.leading)
                
                List(Array(data.keys.sorted()), id: \.self, selection: $selectedClass) { key in
                    Text(key)
                }
                .onChange(of: selectedClass) { 
                    selectedInstance = nil
                }
                .frame(minWidth: 150) // Adjust width of the left list
                
            }
            
            // Middle Column: Instances
            VStack(alignment: .leading) {
                Text("Instances")
                    .font(.headline)
                    .padding(.leading)
                
                if let selectedClass, let insarr = data[selectedClass] {
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
        .onAppear {
            mx.mxScanHeap()
            data = mx.mxFoundHeapObjects as! [String : [String]]
        }
        .frame(minWidth: 300, minHeight: 200) // Adjust width and height of the whole view
        .padding()
    }
}




@objc class HeapViewSwift: NSObject {
 
    @MainActor @objc class func createHeapView() -> NSView {
        
        let view = HeapView()
       
        return NSHostingView(rootView: view)
    }
}

