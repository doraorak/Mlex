//
//  Mlex.h
//  Mlex
//
//  Created by Dora Orak on 25.01.2025.
//

#import "SharedHeader.h"

@interface Mlex : NSObject

@property NSWindow* MxWindow;
@property(strong, nonatomic, nonnull) NSMutableArray* MxFoundHeapObjects;


-(void) MXCreateWindow;

@end
