//
//  Mlex.m
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//

#import "Mlex.h"
#import "Mlex-Swift.h"

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
    
    Mlex* mx = [Mlex sharedInstance];
    
    mx.MxFoundHeapObjects = [NSMutableDictionary new];
    [mx MXCreateWindow];
}

-(void) MXCreateWindow {
    self.MxWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(400, 400, 1800, 1400)
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    
    self.MxWindow.contentView = [[NSView alloc] initWithFrame:self.MxWindow.contentViewController.view.frame];
    
    
    NSTabView *tabView = [[NSTabView alloc] initWithFrame:self.MxWindow.contentView.bounds];
    
    
    NSTabViewItem* tabViewItemHome = [[NSTabViewItem alloc] initWithIdentifier:@"Home"];
    tabViewItemHome.label = @"Home";
    tabViewItemHome.view = [[NSView alloc] initWithFrame:self.MxWindow.contentView.bounds];
    
    NSView *swiftHeapView = [HeapViewSwift createHeapView];
    swiftHeapView.frame = self.MxWindow.contentView.bounds;
    
    NSTabViewItem *tabViewItemHeap = [[NSTabViewItem alloc] initWithIdentifier:@"Heap"];
    tabViewItemHeap.label = @"Heap";
    [tabViewItemHeap setView:swiftHeapView];
   
    
    [tabView addTabViewItem:tabViewItemHome];
    [tabView addTabViewItem:tabViewItemHeap];
    
    [self.MxWindow setContentView:tabView];
    
    [self.MxWindow makeKeyAndOrderFront:nil];
    
}

-(void) MXScanHeap{
    
    [self.MxFoundHeapObjects removeAllObjects];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        heapFind((void *)&(self->_MxFoundHeapObjects));
    });

    }


#pragma mark protocol methods


@end
