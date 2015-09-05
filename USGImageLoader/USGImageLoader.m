//
//  USGImageLoader
//
//  Created by M.Satori on 14.10.30.
//  Copyright (c) 2014 usagimaru.
//

@import UIKit;
#import "USGImageLoader.h"

@interface USGImageLoader () <USGImageDownloadManagerDelegate>

@property (nonatomic) USGImageDownloadManager *imageDownloadManager;

@end

@implementation USGImageLoader

- (instancetype)initWithCache:(nullable USGImageCache*)imageCache
				configuration:(nullable NSURLSessionConfiguration*)configuration
					 delegate:(id<USGImageLoaderDelegate>)delegate
{
	self = [super init];
	if (self) {
		_delegate = delegate;
		_imageDownloadManager = [[USGImageDownloadManager alloc] initWithConfiguration:configuration
																	  customImageCache:imageCache
																			  delegate:self];
	}
	return self;
}
- (instancetype)initWithCache:(nullable USGImageCache*)imageCache
					 delegate:(id<USGImageLoaderDelegate>)delegate
{
	return [[USGImageLoader alloc] initWithCache:imageCache
								   configuration:nil
										delegate:delegate];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self cancelAllTasks];
}


#pragma mark -

- (void)__startDownloadingWithURLString:(NSString*)URLString
{
	__weak __typeof(self) wself = self;
	
	NSURL *URL = [NSURL URLWithString:URLString];
	UIImage *cachedImage = [self.imageDownloadManager.imageCache cachedImageForKey:URLString];
	
	// キャッシュがあるなら復元
	if (cachedImage) {
		// メインスレッドに戻す
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([wself.delegate respondsToSelector:@selector(imageLoader:didFinishLoadingImage:URL:fromCache:error:)]) {
				[wself.delegate imageLoader:wself didFinishLoadingImage:cachedImage URL:URL fromCache:YES error:nil];
			}
		});
	}
	// ダウンロード開始
	else if (![self.imageDownloadManager isTaskRunningForURLString:URLString]) {
		[self.imageDownloadManager startDownloadingFromURL:URL];
	}
}


#pragma mark -

// メモリ警告時
- (void)setCancelsWhenMemoryWarning:(BOOL)cancelsWhenMemoryWarning
{
	_cancelsWhenMemoryWarning = cancelsWhenMemoryWarning;
	
	if (_cancelsWhenMemoryWarning) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIApplicationDidReceiveMemoryWarningNotification
													  object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(cancelAllTasks)
													 name:UIApplicationDidReceiveMemoryWarningNotification
												   object:nil];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIApplicationDidReceiveMemoryWarningNotification
													  object:nil];
	}
}

- (void)loadImages:(NSArray*)URLs
{
	if (URLs.count == 0) {
		return;
	}
	
	// ロードに指定されたURL文字列を用意
	NSMutableSet *loadingURLStringSet = [NSMutableSet set];
	[URLs enumerateObjectsUsingBlock:^(NSURL *URL, NSUInteger idx, BOOL *stop) {
		[loadingURLStringSet addObject:[[URL absoluteString] lowercaseString]];
	}];
	
	// 進捗中のURL文字列から指定分を除外、残ったものをキャンセル
	NSMutableSet *progresses = [NSMutableSet setWithArray:[self.imageDownloadManager progressOfURLStrings]];
	NSMutableSet *shouldCancel = [progresses mutableCopy];
	[shouldCancel minusSet:loadingURLStringSet];
	[self.imageDownloadManager performAction:USGImageDownloadManagerActionCancel URLStrings:[shouldCancel allObjects]];
	
	// 指定分から進捗中を除外して、残ったものを新規にロード開始
	NSMutableSet *waitings = [loadingURLStringSet mutableCopy];
	[waitings minusSet:progresses];
	[waitings enumerateObjectsUsingBlock:^(NSString *URLStriong, BOOL *stop) {
		[self __startDownloadingWithURLString:URLStriong];
	}];
}
- (void)loadImagesAppendingTasks:(NSArray*)URLs
{
	if (URLs.count == 0) {
		return;
	}
	
	// ロードに指定されたURL文字列を用意
	NSMutableSet *loadingURLStringSet = [NSMutableSet set];
	[URLs enumerateObjectsUsingBlock:^(NSURL *URL, NSUInteger idx, BOOL *stop) {
		[loadingURLStringSet addObject:[[URL absoluteString] lowercaseString]];
	}];
	
	// 指定分から進捗中を除外して、残ったものを新規にロード開始
	NSMutableSet *progresses = [NSMutableSet setWithArray:[self.imageDownloadManager progressOfURLStrings]];
	NSMutableSet *waitings = [loadingURLStringSet mutableCopy];
	[waitings minusSet:progresses];
	[waitings enumerateObjectsUsingBlock:^(NSString *URLStriong, BOOL *stop) {
		[self __startDownloadingWithURLString:URLStriong];
	}];
}

- (void)cancelAllTasks
{
	[self.imageDownloadManager cancellAllTasks];
}
- (void)cancelTasks:(NSArray*)URLs
{
	[self.imageDownloadManager performAction:USGImageDownloadManagerActionCancel URLs:URLs];
}

- (USGImageCache*)imageCache
{
	return self.imageDownloadManager.imageCache;
}


#pragma mark - USGImageDownloadManagerDelegate

- (void)imageDownloadManager:(USGImageDownloadManager*)manager
didFinishDownloadImageForURL:(NSURL*)URL
					   image:(nullable UIImage*)image
					   error:(nullable NSError*)error
{
	// メインスレッドに戻す
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([wself.delegate respondsToSelector:@selector(imageLoader:didFinishLoadingImage:URL:fromCache:error:)]) {
			[wself.delegate imageLoader:wself didFinishLoadingImage:image URL:URL fromCache:NO error:error];
		}
	});
}

- (void)imageDownloadManager:(USGImageDownloadManager*)manager
didCancelDownloadImageForURL:(NSURL*)URL
{
	// Canceled
}

@end
