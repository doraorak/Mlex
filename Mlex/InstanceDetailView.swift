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
    @State private var hasAppeared = false
    
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
                         .pickerStyle(MenuPickerStyle())
                         .onAppear{
                             guard !hasAppeared else { return }
                             hasAppeared = true
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
                        HStack{
                            Text(method)
                                .monospaced()
                            
                            Spacer()
                            
                            VStack{
                                if let typenc = method_getTypeEncoding(class_getClassMethod(NSClassFromString(selectedClsScope) , NSSelectorFromString(method))!) {
                                    Text("retval: \(typenc_getReturnType(typenc) ?? "nil")")
                                        .monospaced()
                                    Text("args: \(typenc_getArgumentTypes(typenc) ?? ["nil"])")
                                        .monospaced()
                                }
                                else{
                                    Text("error")
                                }
                                
                                
                            }
                        }
                    }
                }
                
                Section(header: Text("Instance Methods")) {
                    ForEach(instanceMethodsForCls(NSClassFromString(selectedClsScope)) as! [String], id: \.self) { method in
                        HStack{
                            Text(method)
                                .monospaced()
                            
                            Spacer()
                            
                            VStack{
                                if let typenc = method_getTypeEncoding(class_getInstanceMethod(NSClassFromString(selectedClsScope) , NSSelectorFromString(method))!) {
                                    Text("retval: \(typenc_getReturnType(typenc) ?? "nil")")
                                        .monospaced()
                                    Text("args: \(typenc_getArgumentTypes(typenc) ?? ["nil"])")
                                        .monospaced()
                                }
                                else{
                                    Text("error")
                                }
                                
                                
                            }
                        }

                    }
                }
                
                 Section(header: Text("Instance Properties")) {
                     ForEach(Array(Set(instancePropertiesForCls(NSClassFromString(selectedClsScope)) as! [String])), id: \.self) { property in                         HStack{
                             Text(property)
                                 .monospaced()

                             Spacer()
                             
                             let propertyValue = propertyValueForObject(obj!, property)
                            
                             Text(String(describing: propertyValue ?? "nil/NULL"))
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
                 
                 Section(header: Text("Description")) {
                     Text(String(describing: obj!))
                 }
            }
             
                 
        }
    }
}

