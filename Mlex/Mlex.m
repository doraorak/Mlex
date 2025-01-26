//
//  Mlex.m
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//

#import "Mlex.h"

@implementation Mlex

+ (instancetype)sharedInstance {
    static Mlex* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Mlex alloc] init];
    });
    return instance;
}

+(void) load {
    [super load];
    
    dlopen("/System/Library/PrivateFrameworks/Symbolication.framework/Symbolication", RTLD_NOW);
    
    int rt = setuid(0); //set root
    if (rt != 0) {
        NSLog(@"[Mlex] Failed to set root");
    }
    else {
        NSLog(@"[Mlex] Root set");
        NSLog(@"[Mlex] uid: %d", getuid());
    }
    
    Mlex* mx = [Mlex sharedInstance];
    [mx MXCreateWindow];
    [mx MXScanInstances];
}

-(void) MXCreateWindow {
        
    self.MxWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(400, 400, 1200, 1400) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];
        
    [self.MxWindow makeKeyAndOrderFront:nil];
    
    self.MxWindow.contentViewController = [NSTabViewController new];
    self.MxWindow.contentView = [[NSTabView alloc] initWithFrame:NSMakeRect(100, 100, 1000, 1200)];

    //heap find tab
    NSTabViewItem* heapTabViewItem = [NSTabViewItem new];
    heapTabViewItem.label = @"heap";
    
    NSView* heapView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 1200)];
    //customize heapView
    NSScrollView* heapScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 1200)];
    
    
    [heapTabViewItem setView:heapView];
    [self.MxWindow.contentView addTabViewItem:heapTabViewItem];
    
    }

-(id) MXCreateScanner{
    //get the task
    id vmu_task = ((id(*)(id, SEL, task_t))objc_msgSend)([objc_getClass("VMUTask") alloc], sel_registerName("initWithTask:"), mach_task_self());
    if (!vmu_task) {
        NSLog(@"[Mlex] Failed to create VMUTask object");
        return nil;
    }
    //create the scanner
    id scanner = ((id(*)(id, SEL, id, uint64_t))objc_msgSend)([objc_getClass("VMUTaskMemoryScanner")  alloc], sel_registerName("initWithVMUTask:options:"), vmu_task, 2076);
    if (!scanner) {
        NSLog(@"[Mlex] Failed to create VMUTaskMemoryScanner object");
        return nil;
    }
    //configure scanner
    ((void(*)(id, SEL, uint32_t))objc_msgSend)(scanner, sel_registerName("setObjectContentLevel:"), 3);
    ((void(*)(id, SEL, uint32_t))objc_msgSend)(scanner, sel_registerName("setScanningMask:"), VMUScanMaskConservative);
    ((void(*)(id, SEL, BOOL))objc_msgSend)(scanner, sel_registerName("setShowRawClassNames:"), YES);
    ((void(*)(id, SEL, BOOL))objc_msgSend)(scanner, sel_registerName("setAbandonedMarkingEnabled:"), NO);
    
    NSError *error = nil;
    ((void (*)(id, SEL, id *))objc_msgSend)(scanner, sel_registerName("addAllNodesFromTaskWithError:"), &error);
    if (error) {
        NSLog(@"[Mlex] Error adding nodes: %s\n", error.localizedDescription.UTF8String);
        return nil;
    }
    
    return scanner;
}

-(void) MXScanInstances {
    
    __block ProcessStats stats = {0};
    stats.objects = [[NSMutableArray alloc] init];
    
    id scanner = [self MXCreateScanner];
    
    if (!scanner) {
        NSLog(@"[Mlex] Failed to create scanner 2");
        return;
    }
    
    //scan the heap
    ((void (*)(id, SEL, id))objc_msgSend)(scanner, sel_registerName("enumerateObjectsWithBlock:"), ^(uint32_t nodeName, VMUObjectGraphNode nodeInfo, BOOL *stop) {
        id classInfo = nodeInfo.classInfo;
        if (!classInfo) {
            return;
        }
        
        NSString *className = ((NSString *(*)(id, SEL))objc_msgSend)(classInfo, sel_registerName("className"));
        
        stats.object_count++;
        stats.total_size += nodeInfo.length;
        
        NSDictionary *objInfo = @{
            @"className": className,
            @"address": @(nodeInfo.address),
            @"size": @(nodeInfo.length),
            @"classInfo": classInfo
        };
        
        [stats.objects addObject:objInfo];
        
    });
    
    for(NSDictionary *obj in stats.objects) {
        NSLog(@"[Mlex] Found object: %@", obj);
    }
}

@end
