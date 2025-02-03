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
    mx.MxDeallocatedObjects = [NSMutableArray new];
    
    Method deallocMethod = class_getInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc"));
    IMP originalDealloc = method_getImplementation(deallocMethod);
    
    IMP newDealloc = imp_implementationWithBlock(^(__unsafe_unretained id self) {
        NSMutableString *address = @"";
        
        if(self){
            address = [NSString stringWithFormat:@"%p", (void *)self];
        }
        
        // Ensure we call the original dealloc properly
        if (originalDealloc) {
            ((void (*)(id, SEL))originalDealloc)(self, NSSelectorFromString(@"dealloc"));
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if(mx){
                if(mx.MxDeallocatedObjects){
                    
                    @synchronized(mx.MxDeallocatedObjects) {
                        [mx.MxDeallocatedObjects addObject:[address uppercaseString]];
                    }
                }
            }
        });
        
        

    });
    
    method_setImplementation(deallocMethod, newDealloc);

    [mx MXCreateWindow];
    
   
}

-(void) MXCreateWindow {
    self.MxWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(400, 400, 1200, 1400)
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
