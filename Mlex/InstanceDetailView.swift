//
//  InstanceDetailView.swift
//  viewtest
//
//  Created by Dora Orak on 28.01.2025.
//

import SwiftUI

struct InstanceDetailView: View {

    let addr: NSString
    
    var body: some View {

        let obj = objectFromAddressString(addr as String)
        
        if obj == nil {
             AnyView(Text("Invalid object address"))
        }
        else {
            
             List {
                Section(header: Text("Class Hierarchy")) {
                    Text(classHierarchyStringForObject(obj))
                }
                
                Section(header: Text("Class Methods")) {
                    ForEach(classMethodsForObject(obj) as! [String], id: \.self) { method in
                        Text(method)
                    }
                }
                
                Section(header: Text("Instance Methods")) {
                    ForEach(instanceMethodsForObject(obj) as! [String], id: \.self) { method in
                        Text(method)
                    }
                }
                
                Section(header: Text("Instance Properties")) {
                    ForEach(instancePropertiesForObject(obj) as! [String], id: \.self) { property in
                        Text(property)
                    }
                }
                
                Section(header: Text("Instance Variables")) {
                    ForEach(instanceVariablesForObject(obj) as! [String], id: \.self) { ivar in
                        Text(ivar)
                    }
                }
            }
        }
    }
}

