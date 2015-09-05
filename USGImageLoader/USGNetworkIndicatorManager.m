//
//  USGNetworkIndicatorManager.m
//
//  Created by M.Satori on 14.10.22.
//  Copyright (c) 2014 usagimaru.
//

#import "USGNetworkIndicatorManager.h"

static NSString *const kNetworkIndicatorManagerDefaultCount = @"default";

@interface USGNetworkIndicatorManager ()

@property (nonatomic) NSMutableDictionary *countTable;

@end


@implementation USGNetworkIndicatorManager

+ (instancetype)sharedManager
{
	static USGNetworkIndicatorManager *_sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (_sharedManager == nil) {
			_sharedManager = [[self alloc] init];
		}
	});
	return _sharedManager;
}
- (instancetype)init
{
	self = [super init];
	if (self) {
		_countTable = @{}.mutableCopy;
	}
	return self;
}

- (void)__checkCount
{
	// メインスレッドで処理する
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		
		__block BOOL isCount = NO;
		[wself.countTable enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *number, BOOL *stop) {
			
			if ([number integerValue] > 0) {
				isCount = YES;
				*stop = YES;
			}
		}];
		
		if (isCount && [UIApplication sharedApplication].networkActivityIndicatorVisible == NO)
			[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		if (!isCount && [UIApplication sharedApplication].networkActivityIndicatorVisible == YES)
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	});
}

- (void)increaseCount
{
	[self increaseCount:kNetworkIndicatorManagerDefaultCount];
}
- (void)decreaseCount
{
	[self decreaseCount:kNetworkIndicatorManagerDefaultCount];
}
- (void)increaseCount:(id)object
{
	// メインスレッドで処理する
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		id key = @([object hash]);
		
		NSNumber *countNumber = wself.countTable[key];
		NSInteger count = [countNumber integerValue];
		
		count++;
		
		wself.countTable[@([object hash])] = @(count);
		
		[wself __checkCount];
	});
}
- (void)decreaseCount:(id)object
{
	// メインスレッドで処理する
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		id key = @([object hash]);
		NSNumber *countNumber = wself.countTable[key];
		NSInteger count = [countNumber integerValue];
		
		count--;
		if (count < 0) {
			count = 0;
		}
		
		wself.countTable[key] = @(count);
		
		[wself __checkCount];
	});
}
- (void)resetCount:(id)object
{
	// メインスレッドで処理する
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		id key = @([object hash]);
		wself.countTable[key] = @0;
		
		[wself __checkCount];
	});
}

@end
