//
//  USGImageCache.m
//
//  Created by M.Satori on 15.02.01.
//  Copyright (c) 2014 usagimaru.
//

#import "USGImageCache.h"

NSString *const USGImageCacheNameDefault = @"default";
NSString *const USGImageCacheDidRemoveCacheFilesNotification = @"USGImageCacheDidRemoveCacheFilesNotification";
static NSString *const USGImageCacheDirectoryName = @"USGImageCache";

@interface USGImageCache ()

@property (nonatomic) NSOperationQueue *queue;
@property (copy, nonatomic) NSString *cacheDirectory;

@end

@implementation USGImageCache

- (instancetype)init
{
	self = [super init];
	
	if (self) {
		_queue = [[NSOperationQueue alloc] init];
		[self setClearWhenMemoryWarning:YES];
	}
	
	return self;
}
+ (instancetype)imageCacheWithName:(NSString*)name
{
	if (!name) return nil;
	
	USGImageCache *imageCache = [[self alloc] init];
	
	imageCache.name = name;
	[imageCache __setupDirectory:name];
	
	return imageCache;
}
+ (instancetype)defaultImageCache
{
	return [USGImageCache imageCacheWithName:USGImageCacheNameDefault];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -

- (void)__setupDirectory:(NSString*)name
{
	NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
	NSString *components = [NSString stringWithFormat:@"%@/%@", USGImageCacheDirectoryName, name];
	self.cacheDirectory = [cachesDir stringByAppendingPathComponent:components];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.cacheDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory
								  withIntermediateDirectories:YES
												   attributes:nil
														error:nil];
	}
}

// キャッシュファイルパス
- (NSString*)__imageCacheFilePathWithKey:(NSString*)key
{
	NSString *filename = [NSString stringWithFormat:@"%lu", (unsigned long)key.hash];
	return [self.cacheDirectory stringByAppendingPathComponent:filename];
}

// データをファイルに保存
- (void)__writeData:(NSData*)data forKey:(NSString*)key
{
	NSString *cachePath = [self __imageCacheFilePathWithKey:key];
	[self.queue addOperationWithBlock:^{
		
		NSData *data_ = data;
		NSString *cachePath_ = cachePath;
		[data_ writeToFile:cachePath_ atomically:YES];
	}];
}

#pragma mark -

// メモリ警告時
- (void)setClearWhenMemoryWarning:(BOOL)clearWhenMemoryWarning
{
	_clearWhenMemoryWarning = clearWhenMemoryWarning;
	
	if (_clearWhenMemoryWarning) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIApplicationDidReceiveMemoryWarningNotification
													  object:nil];
		
		__weak __typeof(self) wself = self;
		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
														  object:nil
														   queue:[NSOperationQueue mainQueue]
													  usingBlock:^(NSNotification *note) {
														  
														  [wself clearAllMemoryCaches];
													  }];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIApplicationDidReceiveMemoryWarningNotification
													  object:nil];
	}
}

- (void)setImageData:(NSData*)data forKey:(NSString*)key
{
	if (!key) {
		return;
	}
	
	CGFloat scale = [UIScreen mainScreen].scale;
	UIImage *image = [[UIImage alloc] initWithData:data scale:scale];
	
	if (image) {
		// ファイルキャッシュに保存
		[self __writeData:data forKey:key];
		
		// メモリキャッシュに保存
		[super setObject:image forKey:key];
	}
}
- (void)setImageData:(NSData*)data forURL:(NSURL*)URL
{
	[self setImageData:data forKey:[[URL absoluteString] lowercaseString]];
}
- (void)setImage:(UIImage*)image forKey:(NSString*)key
{
	// メモリキャッシュに保持
	[super setObject:image forKey:key];
}
- (void)setImage:(UIImage*)image forURL:(NSURL*)URL
{
	[super setObject:image forKey:[[URL absoluteString] lowercaseString]];
}

- (void)removeImageCacheForKey:(NSString*)key
{
	// メモリキャッシュを削除
	[super removeObjectForKey:key];
	
	// ファイルキャッシュを削除
	NSURL *fileURL = [NSURL fileURLWithPath:[self __imageCacheFilePathWithKey:key]];
	[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
}
- (void)removeImageCacheForURL:(NSURL*)URL
{
	[self removeImageCacheForKey:[[URL absoluteString] lowercaseString]];
}

- (UIImage*)cachedImageForKey:(NSString*)key
{
	if (!key) {
		return nil;
	}
	
	UIImage *cachedImage = [super objectForKey:key];
	
	// メモリキャッシュがなかったらファイルから読み込んでメモリキャッシュに展開する
	if (!cachedImage) {
		NSData *data = [NSData dataWithContentsOfFile:[self __imageCacheFilePathWithKey:key]];
		CGFloat scale = [UIScreen mainScreen].scale;
		cachedImage = [[UIImage alloc] initWithData:data scale:scale];
		
		if (cachedImage) {
			[self setImage:cachedImage forKey:key];
		}
	}
	
	return cachedImage;
}
- (UIImage*)cachedImageForURL:(NSURL*)URL
{
	return [self cachedImageForKey:[[URL absoluteString] lowercaseString]];
}

- (void)removeAllObjects
{
	[super removeAllObjects];
	[self removeAllCacheFiles];
}

// ディレクトリ名を変更 → 空のディレクトリを作成 → 変更したディレクトリを丸ごと削除
- (void)removeAllCacheFiles
{
	@synchronized(self)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		// 一時退避ディレクトリ名
		NSString *renamedCacheDir = [NSString stringWithFormat:@"%@_tmp", self.cacheDirectory];
		
		// 一時退避ディレクトリを削除
		if ([fileManager fileExistsAtPath:renamedCacheDir]) {
			[fileManager removeItemAtPath:renamedCacheDir error:nil];
		}
		
		// ディレクトリ名を変更
		[fileManager moveItemAtPath:self.cacheDirectory
							 toPath:renamedCacheDir
							  error:nil];
		
		// 本来のキャッシュディレクトリを作成
		[[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory
								  withIntermediateDirectories:YES
												   attributes:nil
														error:nil];
		
		// 一時退避ディレクトリを削除
		[fileManager removeItemAtPath:renamedCacheDir error:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:USGImageCacheDidRemoveCacheFilesNotification
															object:self
														  userInfo:nil];
		
		NSLog(@"%s", __PRETTY_FUNCTION__);
	}
}
- (void)clearAllMemoryCaches
{
	[super removeAllObjects];
}

- (NSString*)cacheFullPath
{
	return self.cacheDirectory;
}

@end
