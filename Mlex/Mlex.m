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
    /*
     int rt = setuid(0); //set root
     if (rt != 0) {
     NSLog(@"[Mlex] Failed to set root");
     }
     else {
     NSLog(@"[Mlex] Root set");
     NSLog(@"[Mlex] uid: %d", getuid());
     }
     */
    
    
    
    Mlex* mx = [Mlex sharedInstance];
    [mx MXCreateWindow];
    
    mx.MxFoundHeapObjects = [NSMutableArray new];
    
   
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        heapFind((void *)&(mx->_MxFoundHeapObjects));
        NSLog(@"[Mlex] Found %lu objects", mx.MxFoundHeapObjects.count);
        NSLog(@"[Mlex] FOUNDOBJECTS: %@", mx.MxFoundHeapObjects);
    //});
    
   
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



@end
