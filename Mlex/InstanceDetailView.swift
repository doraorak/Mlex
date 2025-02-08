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
    
    @State var selectedClsScope: String = ""
    
    
    var body: some View {

        let obj: AnyObject? = objectFromAddressString(addr as String) as? AnyObject

        if obj is NSNull || obj == nil {
             Text("Invalid object address")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.red)
        }
        else {
            if let realcls = String(utf8String:class_getName(object_getClass(obj!))) {
                if realcls != selcls {
                    Text("object address reused")
                        .monospaced()
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .foregroundColor(.red)
                }
            }
             List {
                 Section(header: Text("Class Hierarchy")) {
                     
                     let clsHierarchy = classHierarchyForCls(type(of:obj!)) as! [String]
                     
                     VStack{
                         Text(clsHierarchy.joined(separator: "->"))
                             .font(.system(size: 11))
                             .monospaced()
                         
                         Picker(selection: $selectedClsScope, label: Text("Select scope")) {
                             ForEach(clsHierarchy, id: \.self) { cls in
                                 Text(cls).tag(cls)
                                     .monospaced()
                                 
                             }
                         }
                         .pickerStyle(MenuPickerStyle()) // Optional UI tweak
                         .onAppear {
                             let first = clsHierarchy.first
                             selectedClsScope = first!
                         }
                         .onChange(of: addr) {
                             let first = clsHierarchy.first
                             selectedClsScope = first!
                         }
                     }
                 }
                 
                Section(header: Text("Class Methods")) {
                    ForEach(classMethodsForCls(NSClassFromString(selectedClsScope)) as! [String], id: \.self) { method in
                        Text(method)
                            .monospaced()

                    }
                }
                
                Section(header: Text("Instance Methods")) {
                    ForEach(instanceMethodsForCls(NSClassFromString(selectedClsScope)) as! [String], id: \.self) { method in
                        Text(method)
                            .monospaced()

                    }
                }
                
                 Section(header: Text("Instance Properties")) {
                     ForEach(instancePropertiesForCls(NSClassFromString(selectedClsScope)) as! [String], id: \.self) {property in
                         HStack{
                             Text(property)
                                 .monospaced()

                             Spacer()
                             
                             let propertyValue = propertyValueForObject(obj!, property)
                            
                             Text(String(describing: propertyValue).dropFirst(9).dropLast(1))
                                 .monospaced()

                         }
                     }
                 }
                 
                Section(header: Text("Instance Variables")) {
                    ForEach(instanceVariablesForCls(NSClassFromString(selectedClsScope)) as! [String], id: \.self) { ivar in
                        Text(ivar)
                            .monospaced()

                    }
                }
            }
             
                 
        }
    }
}

