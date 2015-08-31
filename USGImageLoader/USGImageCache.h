//
//  USGImageCache.h
//
//  Created by M.Satori on 15.02.01.
//  Copyright (c) 2014 usagimaru.
//

@import Foundation;
@import UIKit;

extern NSString *const USGImageCacheNameDefault;
extern NSString *const USGImageCacheDidRemoveCacheFilesNotification;

@interface USGImageCache : NSCache

@property (nonatomic) BOOL clearWhenMemoryWarning; // default: YES

/**
 *  Initialize new image cache with cache name
 *
 *  @param name Cache name
 */
+ (instancetype)imageCacheWithName:(NSString*)name;
/**
 *  Initialize as default image cache
 */
+ (instancetype)defaultImageCache;

- (void)setImageData:(NSData*)data forKey:(NSString*)key;
- (void)setImageData:(NSData*)data forURL:(NSURL*)URL;
- (void)setImage:(UIImage*)image forKey:(NSString*)key;
- (void)setImage:(UIImage*)image forURL:(NSURL*)URL;

- (void)removeImageCacheForKey:(NSString*)key;
- (void)removeImageCacheForURL:(NSURL*)URL;

- (UIImage*)cachedImageForKey:(NSString*)key;
- (UIImage*)cachedImageForURL:(NSURL*)URL;

/**
 *  Clear all memory caches and files
 */
- (void)removeAllObjects;
/**
 *  Remove all cache files
 */
- (void)removeAllCacheFiles;
/**
 *  Clear all memory caches
 */
- (void)clearAllMemoryCaches;

- (NSString*)cacheFullPath;

@end
