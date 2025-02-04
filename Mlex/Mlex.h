//
//  Mlex.h
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//

#pragma once

#import "SharedHeader.h"

@interface Mlex : NSObject

@property(strong, nonatomic, nonnull) NSWindow* MxWindow;
@property(strong, nonatomic, nonnull) NSMutableDictionary* MxFoundHeapObjects;

+(instancetype) sharedInstance;
-(void) MXScanHeap;
-(void) MXCreateWindow;


#pragma mark Protocol methods



@end
