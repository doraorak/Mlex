//
//  Util.h
//  Mlex
//
//  Created by Dora Orak on 26.01.2025.
//
#pragma once

#import "SharedHeader.h"

BOOL pointerIsReadable(const void *inPtr) { //stolen from FLEX
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
