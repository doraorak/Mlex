//
//  objectFromAddress.m
//  Mlex
//
//  Created by Dora Orak on 5.02.2025.
//

#import "SharedHeader.h"
#import "signal_guard.h"
#import "Util.h"
#import <Foundation/NSDebug.h>

BOOL pointerIsValidObjcObject(const void *ptr) {
    
#if __arm64e__
    ptr = ptrauth_strip(ptr, ptrauth_key_function_pointer);
#endif
    
    uintptr_t pointer = (uintptr_t)ptr;
    
    if (!ptr) {
        NSLog(@"[mlex] pointer ! fail");
        return NO;
    }
    
    // Tagged pointers have 0x1 set, no other valid pointers do
    // objc-internal.h -> _objc_isTaggedPointer()
    if (isTaggedPointer(ptr) || isExtTaggedPointer(ptr)) {
        return YES;
    }
    
    // Check pointer alignment
    if ((pointer % sizeof(uintptr_t)) != 0) {
        NSLog(@"[mlex] pointer alignment fail");
        return NO;
    }
    
    // From LLDB:
    // Pointers in a class_t will only have bits 0 through 46 set,
    // so if any pointer has bits 47 through 63 high, we know that this is not a valid isa
    // https://llvm.org/svn/llvm-project/lldb/trunk/examples/summaries/cocoa/objc_runtime.py
    if ((pointer & 0xFFFF800000000000) != 0) {
        NSLog(@"[mlex] pointer 47-63 fail");
        return NO;
    }
    
    // Make sure dereferencing this address won't crash
    if (!pointerIsReadable(ptr)) {
        NSLog(@"[mlex] pointer is readable fail");
        return NO;
    }
    
    extern uint64_t objc_debug_isa_magic_mask WEAK_IMPORT_ATTRIBUTE;
    extern uint64_t objc_debug_isa_magic_value WEAK_IMPORT_ATTRIBUTE;
    
    if (!((((uint64_t)(((maybe_id*)ptr)->isa)) & objc_debug_isa_magic_mask) == objc_debug_isa_magic_value)) {
        NSLog(@"[mlex] pointer isa magic fail");
        return NO;
    }
    
    // http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
    // We check if the returned class is readable because object_getClass
    // can return a garbage value when given a non-nil pointer to a non-object
    Class cls = NULL;
    WHILE_IGNORING_SIGNALS({cls = object_getClass((__bridge id)ptr);});
    if (cls == NULL || !pointerIsReadable((__bridge void *)cls)) {
        NSLog(@"[mlex] pointer getclass fail");
        return NO;
    }
    
    // Just because this pointer is readable doesn't mean whatever is at
    // it's ISA offset is readable. We need to do the same checks on it's ISA.
    // Even this isn't perfect, because once we call object_isClass, we're
    // going to dereference a member of the metaclass, which may or may not
    // be readable itself. For the time being there is no way to access it
    // to check here, and I have yet to hard-code a solution.
    Class metaclass = NULL;
    WHILE_IGNORING_SIGNALS({metaclass = object_getClass(cls);});
    if (metaclass == NULL|| !pointerIsReadable((__bridge void *)metaclass)) {
        return NO;
    }
    
    if(NSIsFreedObject((__bridge id)ptr)){
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


id objectFromAddressString(NSString *hexAddressString) {
    unsigned long long address = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexAddressString];
    [scanner setScanLocation:2]; // Skip the "0x" prefix
    [scanner scanHexLongLong:&address];
            
        
        if(pointerIsValidObjcObject((void*)address)){
        
        // Cast the address to an Objective-C id
        #if __arm64e__
            address = (unsigned long long)ptrauth_strip((void *)address, ptrauth_key_function_pointer);
        #endif
            
            id object = (__bridge id)((void *)address); //__unsafe_unretained
            
            if(object)
                return object;
        }
    
    return nil;
}
