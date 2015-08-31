//
//  USGNetworkIndicatorManager.h
//
//  Created by M.Satori on 14.10.22.
//  Copyright (c) 2014 usagimaru.
//

#import <UIKit/UIKit.h>

@interface USGNetworkIndicatorManager : NSObject

+ (instancetype)sharedManager;

- (void)increaseCount;
- (void)decreaseCount;
- (void)increaseCount:(id)object;
- (void)decreaseCount:(id)object;
- (void)resetCount:(id)object;

@end
