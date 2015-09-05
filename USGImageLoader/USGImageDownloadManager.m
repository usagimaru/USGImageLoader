//
//  USGImageDownloadManager.m
//
//  Created by M.Satori on 15.08.30.
//  Copyright (c) 2015 usagimaru. All rights reserved.
//

#import "USGImageDownloadManager.h"
#import "USGNetworkIndicatorManager.h"

NS_ASSUME_NONNULL_BEGIN
@interface USGImageDownloadManager () <NSURLSessionDelegate>

@property (nonatomic) NSURLSessionConfiguration *configuration;
@property (nonatomic) NSURLSession *URLSession;
@property (nonatomic) NSMapTable *taskTable;
@property (nonatomic) NSMutableDictionary *imageDataTemps;
@property (nonatomic) NSOperationQueue *queue;

@end

@implementation USGImageDownloadManager

- (nullable instancetype)initWithConfiguration:(nullable NSURLSessionConfiguration*)configuration
							  customImageCache:(nullable USGImageCache*)customImageCache
									  delegate:(id<USGImageDownloadManagerDelegate>)delegate
{
	self = [super init];
	
	if (self) {
		self.delegate = delegate;
		self.taskTable = [NSMapTable strongToWeakObjectsMapTable];
		self.imageDataTemps = @{}.mutableCopy;
		
		// デフォルトキャッシュを設定
		if (!customImageCache) {
			customImageCache = [USGImageCache defaultImageCache];
		}
		self.imageCache = customImageCache;
		
		// NSURLSessionConfiguration を設定
		if (!configuration) {
			configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
			configuration.HTTPMaximumConnectionsPerHost = 6; // 通信の同時接続数（並列化）
		}
		
		self.configuration = configuration;
		self.queue = [NSOperationQueue mainQueue];
		
		[self __makeSession];
	}
	
	return self;
}

- (void)__makeSession
{
	self.URLSession = [NSURLSession sessionWithConfiguration:self.configuration
													delegate:self
											   delegateQueue:self.queue];
}

- (void)startDownloadingFromURL:(NSURL*)URL
{
	NSString *key = [[URL absoluteString] lowercaseString];
	
	NSURLSessionDataTask *task = nil;
	NSURLSessionDataTask *existingTask = [self.taskTable objectForKey:key];
	
	// 既存のタスクがある場合
	if (existingTask) {
		// 既存のタスクが実行中なら何もせずに終了
		if (existingTask.state == NSURLSessionTaskStateRunning) {
			return;
		}
		
		task = existingTask;
	}
	else {
		// 新たなタスクを作成
		task = [self.URLSession dataTaskWithURL:URL];
		[self.taskTable setObject:task forKey:key];
		[self.imageDataTemps removeObjectForKey:key];
	}
	
	
	// タスクを実行
	[task resume];
	[[USGNetworkIndicatorManager sharedManager] increaseCount:self];
}

- (void)__performAction:(USGImageDownloadManagerAction)action task:(NSURLSessionDataTask*)task
			  URLString:(NSString*)key
{
	if (!task) {
		return;
	}
	
	// タスクに対する処理を実行
	switch (action) {
		case USGImageDownloadManagerActionCancel: {
			[task cancel];
			[self.imageDataTemps removeObjectForKey:key];
			[self.taskTable removeObjectForKey:key];
		} break;
		case USGImageDownloadManagerActionSuspend: {
			[task suspend];
		} break;
		case USGImageDownloadManagerActionResume: {
			[task resume];
		} break;
	}
}
- (void)performAction:(USGImageDownloadManagerAction)action URL:(NSURL*)URL
{
	NSString *key = [[URL absoluteString] lowercaseString];
	NSURLSessionDataTask *existingTask = [self.taskTable objectForKey:key];
	
	[self __performAction:action task:existingTask URLString:key];
}
- (void)performAction:(USGImageDownloadManagerAction)action URLs:(NSArray*)URLs
{
	[URLs enumerateObjectsUsingBlock:^(NSURL *URL, NSUInteger idx, BOOL *stop) {
		[self performAction:action URL:URL];
	}];
}
- (void)performAction:(USGImageDownloadManagerAction)action URLStrings:(NSArray*)URLStrings
{
	[URLStrings enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
		NSURLSessionDataTask *existingTask = [self.taskTable objectForKey:key];
		
		[self __performAction:action task:existingTask URLString:key];
	}];
}

- (void)cancellAllTasks
{
	[self.URLSession invalidateAndCancel];
	[self.taskTable removeAllObjects];
	[self.imageDataTemps removeAllObjects];
	[self __makeSession];
}

- (void)invalidateSession
{
	[self.URLSession invalidateAndCancel];
	[[USGNetworkIndicatorManager sharedManager] resetCount:self];
}

- (NSArray*)progressOfURLs
{
	NSMutableArray *URLs = @[].mutableCopy;
	[[self progressOfURLStrings] enumerateObjectsUsingBlock:^(NSString *URLString, NSUInteger idx, BOOL *stop) {
		[URLs addObject:[NSURL URLWithString:URLString]];
	}];
	return URLs;
}
- (NSArray*)progressOfURLStrings
{
	NSArray *URLs = [[self.taskTable keyEnumerator] allObjects];
	if (!URLs) URLs = @[];
	return URLs;
}

- (BOOL)isTaskRunningForURL:(NSURL*)URL
{
	NSString *key = [[URL absoluteString] lowercaseString];
	NSURLSessionDataTask *existingTask = [self.taskTable objectForKey:key];
	if (!existingTask) return NO;
	return existingTask.state == NSURLSessionTaskStateRunning;
}
- (BOOL)isTaskRunningForURLString:(NSString*)URLString
{
	NSURLSessionDataTask *existingTask = [self.taskTable objectForKey:[URLString lowercaseString]];
	if (!existingTask) return NO;
	return existingTask.state == NSURLSessionTaskStateRunning;
}


#pragma mark - NSURLSessionDelegate

// finishTasksAndInvalidate によってタスクが破棄された場合に呼ばれる
//- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
//{
//	
//}


#pragma mark - NSURLSessionTaskDelegate

// タスクの終了で通知される
// 成功・失敗・キャンセルいずれでもここにくる
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
	__weak __typeof(self) wself = self;
	
	NSURL *URL = task.originalRequest.URL;
	NSString *key = [[URL absoluteString] lowercaseString];
	[self.taskTable removeObjectForKey:key];
	
	// 画像データをキャッシュに設定
	if (!error) {
		NSData *imageData = self.imageDataTemps[key];
		[self.imageCache setImageData:imageData forKey:key];
	}
	// キャンセル
	else if (error.code == NSURLErrorCancelled) {
		if ([self.delegate respondsToSelector:@selector(imageDownloadManager:didCancelDownloadImageForURL:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[wself.delegate imageDownloadManager:wself didCancelDownloadImageForURL:URL];
			});
		}
	}
	
	// 一時画像データを削除
	[self.imageDataTemps removeObjectForKey:key];
	
	// キャンセルではないタスク終了を通知
	if (error.code != NSURLErrorCancelled && [self.delegate respondsToSelector:@selector(imageDownloadManager:didFinishDownloadImageForURL:image:error:)]) {
		UIImage *image = [self.imageCache cachedImageForKey:key];
		dispatch_async(dispatch_get_main_queue(), ^{
			[wself.delegate imageDownloadManager:wself didFinishDownloadImageForURL:URL image:image error:error];
		});
	}
	
	[[USGNetworkIndicatorManager sharedManager] decreaseCount:self];
}


#pragma mark - NSURLSessionDataDelegate

//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
//didReceiveResponse:(NSURLResponse *)response
// completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
//{
//	
//}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
	didReceiveData:(NSData *)data
{
	NSString *key = [[dataTask.originalRequest.URL absoluteString] lowercaseString];
	NSMutableData *imageData = self.imageDataTemps[key];
	
	if (!imageData) {
		imageData = [NSMutableData data];
		self.imageDataTemps[key] = imageData;
	}
	
	[imageData appendData:data];
}

@end
NS_ASSUME_NONNULL_END
