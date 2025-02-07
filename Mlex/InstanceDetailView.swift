//
//  InstanceDetailView.swift
//  viewtest
//
//  Created by Dora Orak on 28.01.2025.
//

import SwiftUI

struct InstanceDetailView: View {

    let addr: NSString
    @Binding var selcls: String?
    
    var body: some View {

        let obj = objectFromAddressString(addr as String)
        
        if obj == nil {
             Text("Invalid object address")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.red)
        }
        else {
            if let realcls = String(utf8String:class_getName(object_getClass(obj))) {
                if realcls != selcls {
                    Text("object address reused")
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .foregroundColor(.red)
                }
            }
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
                    ForEach(instancePropertiesForObject(obj) as! [String], id: \.self) {property in
                        HStack{
                            Text("\(property): ")
                            Spacer()
                            Text(String(describing: propertyValueForObject(obj, property)))
                        }
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

