//
//  Mlex.h
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//

#import "SharedHeader.h"

@interface Mlex : NSObject <NSTableViewDataSource>

@property(strong, nonatomic, nonnull) NSWindow* MxWindow;
@property(strong, nonatomic, nonnull) NSMutableDictionary* MxFoundHeapObjects;
@property(strong, nonatomic, nonnull) NSString* MxSelectedClass;

-(void) MXCreateWindow;


#pragma mark Protocol methods



@end
