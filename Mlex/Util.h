//
//  Util.h
//  Mlex
//
//  Created by Dora Orak on 26.01.2025.
//
#pragma once

#import <mach/mach.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <malloc/malloc.h>

typedef struct {
    Class isa;
} maybe_id;

static NSString* classHierarchyStringForObject(id object) {
    
    NSMutableString *description = [NSMutableString string];
    Class cls = object_getClass(object);
    
    while (cls) {
        [description appendFormat:@"%@   ", NSStringFromClass(cls)];
        cls = class_getSuperclass(cls);
    }
    return description;
}

static NSArray* classMethodsForObject(id object) {
    
    unsigned int count;
    Method *methods = class_copyMethodList(object_getClass([object class]), &count); //object_GetClass(Class cls) returns the metaclass of the argument
    NSMutableArray *methodsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [methodsArray addObject:NSStringFromSelector(method_getName(methods[i]))];
    }
    free(methods);
    
    return methodsArray;
}

static NSArray* instanceMethodsForObject(id object) {
    
    unsigned int count;
    Method *methods = class_copyMethodList([object class], &count);
    NSMutableArray *methodsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [methodsArray addObject:NSStringFromSelector(method_getName(methods[i]))];
    }
    free(methods);
    
    return methodsArray;
}

static NSArray* classPropertiesForObject(id object) {
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(object_getClass([object class]), &count);
    NSMutableArray *propertiesArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [propertiesArray addObject:[NSString stringWithUTF8String:property_getName(properties[i])]];
    }
    free(properties);
    
    return propertiesArray;
}

static NSArray* instancePropertiesForObject(id object) {
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([object class], &count);
    NSMutableArray *propertiesArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [propertiesArray addObject:[NSString stringWithUTF8String:property_getName(properties[i])]];
    }
    free(properties);
    
    return propertiesArray;
}

static NSString* propertyValueForObject(id object, NSString *property) {
    if ([object respondsToSelector:(NSSelectorFromString(property))]){
        return [object valueForKey:property];
    }
    return nil;
}

static NSArray* instanceVariablesForObject(id object) {
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList([object class], &count);
    NSMutableArray *ivarsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [ivarsArray addObject:[NSString stringWithUTF8String:ivar_getName(ivars[i])]];
    }
    free(ivars);
    
    return ivarsArray;
}

#pragma mark - Object from address

static BOOL pointerIsReadable(const void *inPtr) { //stolen from FLEX
    kern_return_t error = KERN_SUCCESS;
    
    vm_size_t vmsize;
#if __arm64e__
    // On arm64e, we need to strip the PAC from the pointer so the adress is readable
    vm_address_t address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    vm_address_t address = (vm_address_t)inPtr;
#endif
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    memory_object_name_t object;
    
    error = vm_region_64(
                         mach_task_self(),
                         &address,
                         &vmsize,
                         VM_REGION_BASIC_INFO,
                         (vm_region_info_t)&info,
                         &info_count,
                         &object
                         );
    
    if (error != KERN_SUCCESS) {
        // vm_region/vm_region_64 returned an error
        return NO;
    } else if (!(BOOL)(info.protection & VM_PROT_READ)) {
        return NO;
    }
#if __arm64e__
    address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    address = (vm_address_t)inPtr;
#endif
    
    // Read the memory
    vm_size_t size = 0;
    char buf[sizeof(uintptr_t)];
    error = vm_read_overwrite(mach_task_self(), address, sizeof(uintptr_t), (vm_address_t)buf, &size);
    if (error != KERN_SUCCESS) {
        // vm_read_overwrite returned an error
        return NO;
    }

    return YES;
 }

//FIXME: non portable
static BOOL isTaggedPointer(const void *ptr) {
    return ((uintptr_t)ptr & (1UL<<63)) == (1UL<<63);
}


static BOOL isExtTaggedPointer(const void *ptr) {
    return ((uintptr_t)ptr & (0xfUL<<60)) == (0xfUL<<60);
}
    

static BOOL pointerIsValidObjcObject(const void *ptr) {
    
#if __arm64e__
    ptr = ptrauth_strip(ptr, ptrauth_key_function_pointer);
#endif
    
    uintptr_t pointer = (uintptr_t)ptr;

    if (!ptr) {
        return NO;
    }

    // Tagged pointers have 0x1 set, no other valid pointers do
    // objc-internal.h -> _objc_isTaggedPointer()
    if (isTaggedPointer(ptr) || isExtTaggedPointer(ptr)) {
        return YES;
    }

    // Check pointer alignment
    if ((pointer % sizeof(uintptr_t)) != 0) {
        return NO;
    }

    // From LLDB:
    // Pointers in a class_t will only have bits 0 through 46 set,
    // so if any pointer has bits 47 through 63 high, we know that this is not a valid isa
    // https://llvm.org/svn/llvm-project/lldb/trunk/examples/summaries/cocoa/objc_runtime.py
    if ((pointer & 0xFFFF800000000000) != 0) {
        return NO;
    }

    // Make sure dereferencing this address won't crash
    if (!pointerIsReadable(ptr)) {
        return NO;
    }
    
    extern uint64_t objc_debug_isa_magic_mask WEAK_IMPORT_ATTRIBUTE;
    extern uint64_t objc_debug_isa_magic_value WEAK_IMPORT_ATTRIBUTE;
    
    if (!((((uint64_t)(((maybe_id*)ptr)->isa)) & objc_debug_isa_magic_mask) == objc_debug_isa_magic_value)) {
        return NO;
    }
    
    // http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
    // We check if the returned class is readable because object_getClass
    // can return a garbage value when given a non-nil pointer to a non-object
    Class cls = object_getClass((__bridge id)ptr);
    if (!cls || !pointerIsReadable((__bridge void *)cls)) {
        return NO;
    }
    
    // Just because this pointer is readable doesn't mean whatever is at
    // it's ISA offset is readable. We need to do the same checks on it's ISA.
    // Even this isn't perfect, because once we call object_isClass, we're
    // going to dereference a member of the metaclass, which may or may not
    // be readable itself. For the time being there is no way to access it
    // to check here, and I have yet to hard-code a solution.
    Class metaclass = object_getClass(cls);
    if (!metaclass || !pointerIsReadable((__bridge void *)metaclass)) {
        return NO;
    }
    
    // Does the class pointer we got appear as a class to the runtime?
    if (!object_isClass(cls)) {
        return NO;
    }
    
    // Is the allocation size at least as large as the expected instance size?
    ssize_t instanceSize = class_getInstanceSize(cls);
    if (malloc_size(ptr) < instanceSize) {
        return NO;
    }

    return YES;
}


static id objectFromAddressString(NSString *hexAddressString) {
    unsigned long long address = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexAddressString];
    [scanner setScanLocation:2]; // Skip the "0x" prefix
    [scanner scanHexLongLong:&address];
            
        
        if(pointerIsValidObjcObject((void*)address)){
        
        // Cast the address to an Objective-C id
        #if __arm64e__
            address = (unsigned long long)ptrauth_strip((void *)address, ptrauth_key_function_pointer);
        #endif
            
            id __unsafe_unretained object = (__bridge id)((void *)address);
            
            if(object)
                return object;
        }
    
    return nil;
}
