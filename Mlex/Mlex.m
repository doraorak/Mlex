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
    [super load];
    
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
    mx.MxFoundHeapObjects = [NSMutableDictionary new];

    [mx MXCreateWindow];
    
   
}

-(void) MXCreateWindow {
    self.MxWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(400, 400, 1200, 1400)
                                                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    
    NSViewController *vc = [[NSViewController alloc] init];
    
    [self MXScanHeap];
    
    NSViewController* svc = [HeapViewSwift createHeapViewController: self.MxFoundHeapObjects];
    [self.MxWindow setContentViewController:vc];
    
    self.MxWindow.contentViewController.view.frame = self.MxWindow.frame;
    svc.view.frame = self.MxWindow.contentViewController.view.bounds;
    
    [self.MxWindow.contentViewController presentViewControllerAsModalWindow:svc];
    
    //[self.MxWindow setTitle:@"Mlex"];
    //[self.MxWindow makeKeyAndOrderFront:nil];
    
}

-(void) MXScanHeap{
    [self.MxFoundHeapObjects removeAllObjects];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        heapFind((void *)&(self->_MxFoundHeapObjects));
        NSLog(@"[Mlex] %@", self.MxFoundHeapObjects);
    });
}

#pragma mark protocol methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if ([tableView.identifier isEqualToString: @"Classes"]){
        return self.MxFoundHeapObjects.allKeys.count;
    }
    else if ([tableView.identifier isEqualToString: @"Instances"]){
        return [[self.MxFoundHeapObjects objectForKey:self.MxSelectedClass] count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableView.identifier isEqualToString: @"Classes"]){
        return [self.MxFoundHeapObjects.allKeys objectAtIndex:row];
    }
    else if ([tableView.identifier isEqualToString: @"Instances"]){
        return [[self.MxFoundHeapObjects objectForKey:self.MxSelectedClass] objectAtIndex:row];
    }
    return 0;

}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    if ([tableView.identifier isEqualToString: @"Classes"]){
        self.MxSelectedClass = [self.MxFoundHeapObjects.allKeys objectAtIndex:tableView.selectedRow];
    }
}


@end
