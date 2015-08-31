//
//  USGImageLoader
//
//  Created by M.Satori on 14.10.30.
//  Copyright (c) 2014 usagimaru.
//

#import <Foundation/Foundation.h>
#import "USGImageDownloadManager.h"
#import "USGImageCache.h"

@protocol USGImageLoaderDelegate;

NS_ASSUME_NONNULL_BEGIN
@interface USGImageLoader : NSObject

/// Delegate
@property (weak, nonatomic) id<USGImageLoaderDelegate> delegate;
/// Cancels when memory warning
@property (nonatomic) BOOL cancelsWhenMemoryWarning;

/**
 *  Initialize new ImageLoader instance.
 *
 *  @param imageCache USGImageCache
 *  @param delegate   Delegate
 *
 *  @return USGImageLoader
 */
- (instancetype)initWithCache:(nullable USGImageCache*)imageCache
					 delegate:(id<USGImageLoaderDelegate>)delegate;

/**
 *  Start image loading.
 *  @param URLs @[NSURL]
 */
- (void)loadImages:(NSArray*)URLs;
/**
 *  Start image loading appends.
 *  @param URLs @[NSURL]
 */
- (void)loadImagesAppendingTasks:(NSArray*)URLs;

/// Cancel all tasks.
- (void)cancelAllTasks;
/// Cancel task for URL.
- (void)cancelTasks:(NSArray*)URLs;

/// Return image cache.
- (USGImageCache*)imageCache;

@end

@protocol USGImageLoaderDelegate <NSObject>

/**
 *  Notify when finished image loading.
 *
 *  @param imageLoader USGImageLoader
 *  @param image       画像
 *  @param URL         URL
 *  @param fromCache   Loaded from image cache (BOOL)
 *  @param error       NSError if error existing
 */
- (void)imageLoader:(USGImageLoader*)imageLoader didFinishLoadingImage:(UIImage*)image
				URL:(NSURL*)URL
		  fromCache:(BOOL)fromCache
			  error:(nullable NSError*)error;

@end
NS_ASSUME_NONNULL_END
