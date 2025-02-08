//
//  Util.h
//  Mlex
//
//  Created by Dora Orak on 26.01.2025.
//
#pragma once

#import <mach/mach.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>
#import <malloc/malloc.h>

typedef struct {
    Class _Nonnull isa;
} maybe_id;



#pragma mark object utilities

static NSArray* _Nullable classHierarchyForCls(Class _Nullable cls) {
    
    NSMutableArray* classHierarchy = [NSMutableArray array];
    
    while (cls) {
        [classHierarchy addObject:NSStringFromClass(cls)];
        cls = [cls superclass];
    }
    
    return classHierarchy;
}

static NSArray* _Nullable classMethodsForCls(Class _Nullable cls) {
    
    unsigned int count;
    Method *methods = class_copyMethodList(object_getClass(cls), &count); //object_GetClass(Class cls) returns the metaclass of the argument
    NSMutableArray *methodsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [methodsArray addObject:NSStringFromSelector(method_getName(methods[i]))];
    }
    free(methods);
    
    return methodsArray;
}

static NSArray* _Nullable instanceMethodsForCls(Class _Nullable cls) {
    
    unsigned int count;
    Method *methods = class_copyMethodList(cls, &count);
    NSMutableArray *methodsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [methodsArray addObject:NSStringFromSelector(method_getName(methods[i]))];
    }
    free(methods);
    
    return methodsArray;
}

static NSArray* _Nullable classPropertiesForCls(Class _Nullable cls) {
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(object_getClass(cls), &count);
    NSMutableArray *propertiesArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [propertiesArray addObject:[NSString stringWithUTF8String:property_getName(properties[i])]];
    }
    free(properties);
    
    return propertiesArray;
}

static NSArray* _Nullable instancePropertiesForCls(Class _Nullable cls) {
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    NSMutableArray *propertiesArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [propertiesArray addObject:[NSString stringWithUTF8String:property_getName(properties[i])]];
    }
    free(properties);
    
    return propertiesArray;
}

static id _Nullable propertyValueForObject(id _Nullable object, NSString* _Nullable property) {
    SEL selector = NSSelectorFromString(property);
    if ([object respondsToSelector:selector]) {
        @try {
            return [object valueForKey:property];
        }
        @catch (NSException *exception) {
            NSLog(@"[mlex] kvo Exception: %@", exception);
            return nil;
        }
    }
    return nil;
}

static NSArray* _Nullable instanceVariablesForCls(Class _Nullable cls) {
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList(cls, &count);
    NSMutableArray *ivarsArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [ivarsArray addObject:[NSString stringWithUTF8String:ivar_getName(ivars[i])]];
    }
    free(ivars);
    
    return ivarsArray;
}

static BOOL pointerIsReadable(const void* _Nullable inPtr) { //stolen from FLEX
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
    mach_vm_size_t machsize = 1;
        char dummy;
        if (mach_vm_read_overwrite(mach_task_self(), address, machsize, (mach_vm_address_t)&dummy, &machsize) != KERN_SUCCESS) {
            NSLog(@"[mlex] Failed to read memory for: %p", (void*)address);
            return NO;
        }
    
    
    vm_size_t size = 0;
    char buf[sizeof(uintptr_t)];
    error = vm_read_overwrite(mach_task_self(), address, sizeof(uintptr_t), (vm_address_t)buf, &size);
    if (error != KERN_SUCCESS) {
        // vm_read_overwrite returned an error
        NSLog(@"[mlex] Failed to read vm memory for: %p", (void*)address);
        return NO;
    }

    return YES;
 }

//FIXME: non portable
static BOOL isTaggedPointer(const void* _Nullable ptr) {
    return ((uintptr_t)ptr & (1UL<<63)) == (1UL<<63);
}


static BOOL isExtTaggedPointer(const void* _Nullable ptr) {
    return ((uintptr_t)ptr & (0xfUL<<60)) == (0xfUL<<60);
}
