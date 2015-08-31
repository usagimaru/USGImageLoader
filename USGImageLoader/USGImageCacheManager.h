//
//  USGImageCacheManager.h
//
//  Created by M.Satori on 15.02.01.
//  Copyright (c) 2015 usagimaru.
//

#import <Foundation/Foundation.h>
@class USGImageCache;

@interface USGImageCacheManager : NSObject

@property (nonatomic, readonly) NSUInteger cacheCount;
@property (nonatomic, readonly) NSArray *allCacheKeys;

+ (instancetype)sharedManager;

- (void)setImageCache:(USGImageCache*)imageCache;
- (void)setImageCache:(USGImageCache*)imageCache forKey:(NSString*)key;
- (USGImageCache*)imageCacheForKey:(NSString*)key;
- (void)removeImageCacheForKey:(NSString*)key;
- (void)removeAllImageCaches;

@end

@interface USGImageCacheManager (USGImageCacheAddition)

+ (USGImageCache*)defaultImageCache;

@end
