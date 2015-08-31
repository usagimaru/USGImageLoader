//
//  USGImageCacheManager.m
//
//  Created by M.Satori on 15.02.01.
//  Copyright (c) 2015 usagimaru.
//

#import "USGImageCacheManager.h"
#import "USGImageCache.h"

@interface USGImageCacheManager ()

@property (nonatomic, readwrite) NSUInteger cacheCount;
@property (nonatomic, readwrite) NSArray *allCacheKeys;

@property (nonatomic) NSMutableDictionary *caches;

@end

@implementation USGImageCacheManager

+ (instancetype)sharedManager
{
	static dispatch_once_t onceToken;
	static USGImageCacheManager *_sharedManager;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[USGImageCacheManager alloc] init];
	});
	
	return _sharedManager;
}

- (instancetype)init
{
	self = [super init];
	
	if (self) {
		_caches = @{}.mutableCopy;
		
		[self setImageCache:[USGImageCache defaultImageCache]];
	}
	
	return self;
}

- (void)setImageCache:(USGImageCache*)imageCache
{
	[self setImageCache:imageCache forKey:imageCache.name];
}
- (void)setImageCache:(USGImageCache*)imageCache forKey:(NSString*)key
{
	self.caches[key] = imageCache;
}
- (USGImageCache*)imageCacheForKey:(NSString*)key
{
	return self.caches[key];
}
- (void)removeImageCacheForKey:(NSString*)key
{
	[self.caches removeObjectForKey:key];
}
- (void)removeAllImageCaches
{
	[self.caches removeAllObjects];
}

- (NSUInteger)cacheCount
{
	return self.caches.count;
}
- (NSArray*)allCacheKeys
{
	return self.caches.allKeys;
}

@end

@implementation USGImageCacheManager (USGImageCacheAddition)

+ (USGImageCache*)defaultImageCache
{
	return [[USGImageCacheManager sharedManager] imageCacheForKey:USGImageCacheNameDefault];
}

@end
