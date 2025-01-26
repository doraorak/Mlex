//
//  SharedHeader.h
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//
#pragma once

#import <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <malloc/malloc.h>

void heapFind(void* ptr);


typedef struct {
    Class isa;
} maybe_id;

typedef struct _VMUObjectGraphNode {
    uint64_t address;
    uint64_t length : 60;
    uint64_t nodeType : 4;
    __unsafe_unretained id classInfo;
} VMUObjectGraphNode;

typedef struct {
    char process_name[256];
    pid_t pid;
    uint64_t object_count;
    uint64_t total_size;
    NSMutableArray *objects;
} ProcessStats;

typedef NS_ENUM(uint32_t, VMUScanMask) {
    VMUScanMaskNone               = 0,
    VMUScanMaskConservative       = 1,
    VMUScanMaskStrongRef         = 2,
    VMUScanMaskUnownedRef        = 3,
    VMUScanMaskWeakRef           = 4,
    VMUScanMaskSwiftWeakRef      = 5,
    VMUScanMaskUnsafeUnretained  = 8,
    VMUScanMaskMaxValue          = VMUScanMaskUnsafeUnretained,
};




