//
//  USGImageDownloadManager.h
//
//  Created by M.Satori on 15.08.30.
//  Copyright (c) 2015 usagimaru. All rights reserved.
//

@import UIKit;
#import "USGImageCache.h"

@protocol USGImageDownloadManagerDelegate;

/**
 *  タスクに対するアクション
 */
typedef NS_ENUM(NSInteger, USGImageDownloadManagerAction){
	/**
	 *  キャンセル
	 */
	USGImageDownloadManagerActionCancel,
	/**
	 *  一時停止
	 */
	USGImageDownloadManagerActionSuspend,
	/**
	 *  実行／再開
	 */
	USGImageDownloadManagerActionResume
};

NS_ASSUME_NONNULL_BEGIN
@interface USGImageDownloadManager : NSObject

/// 画像キャッシュ
@property (nonatomic) USGImageCache *imageCache;
/// デリゲート
@property (weak, nonatomic) id<USGImageDownloadManagerDelegate> delegate;

/**
 *  画像ダウンローダーを初期化する
 *
 *  @param configuration    NSURLSessionConfiguration
 *  @param customImageCache 画像キャッシュ
 *  @param delegate         デリゲート
 *  @discussion NSURLSessionConfiguration.HTTPMaximumConnectionsPerHost を利用すると画像を並列ダウンロードすることができる。
 *
 *  @return USGImageDownloadManager
 */
- (nullable instancetype)initWithConfiguration:(nullable NSURLSessionConfiguration*)configuration
							  customImageCache:(nullable USGImageCache*)customImageCache
									  delegate:(id<USGImageDownloadManagerDelegate>)delegate;

/// 画像ダウンロードを開始
- (void)startDownloadingFromURL:(NSURL*)URL;

/**
 *  タスクに対するアクションを実行
 *
 *  @param action USGImageDownloadManagerAction
 *  @param URL    タスクに対応する NSURL
 */
- (void)performAction:(USGImageDownloadManagerAction)action URL:(NSURL*)URL;
/**
 *  タスクに対するアクションを実行（複数指定版）
 *
 *  @param action USGImageDownloadManagerAction
 *  @param URLs   タスクに対応する NSURL の配列
 */
- (void)performAction:(USGImageDownloadManagerAction)action URLs:(NSArray*)URLs;
/**
 *  タスクに対するアクションを実行（複数指定版、URL 文字列版）
 *
 *  @param action     USGImageDownloadManagerAction
 *  @param URLStrings タスクに対応する URL 文字列の配列
 */
- (void)performAction:(USGImageDownloadManagerAction)action URLStrings:(NSArray*)URLStrings;

/// すべてのタスクをキャンセル
- (void)cancellAllTasks;
/// セッションを無効化
- (void)invalidateSession;

/// 実行中タスクの NSURL を返す
- (NSArray*)progressOfURLs;
/// 実行中タスクの URL 文字列を返す
- (NSArray*)progressOfURLStrings;

/// URL に対応するタスクが実行中かを返す
- (BOOL)isTaskRunningForURL:(NSURL*)URL;
/// URL 文字列に対応するタスクが実行中かを返す
- (BOOL)isTaskRunningForURLString:(NSString*)URLString;

@end

@protocol USGImageDownloadManagerDelegate <NSObject>

/**
 *  画像ダウンロードが成功もしくは失敗した場合に通知される
 *
 *  @param manager USGImageDownloadManager
 *  @param URL     NSURL
 *  @param image   画像
 *  @param error   失敗なら NSError
 */
- (void)imageDownloadManager:(USGImageDownloadManager*)manager
didFinishDownloadImageForURL:(NSURL*)URL
					   image:(nullable UIImage*)image
					   error:(nullable NSError*)error;

/**
 *  画像ダウンロードがキャンセルされたら通知される
 *
 *  @param manager USGImageDownloadManager
 *  @param URL     NSURL
 */
- (void)imageDownloadManager:(USGImageDownloadManager*)manager
didCancelDownloadImageForURL:(NSURL*)URL;

@end

NS_ASSUME_NONNULL_END
