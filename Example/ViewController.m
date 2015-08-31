//
//  ViewController.m
//
//  Created by M.Satori on 15.01.27.
//  Copyright (c) 2015 usagimaru.
//

#import "ViewController.h"
#import "TableViewCell.h"
#import "USGImageLoader.h"

@interface ViewController () <USGImageLoaderDelegate>

@property (nonatomic) USGImageLoader *imageLoader;
@property (nonatomic) NSMutableArray *URLs;

- (IBAction)clearCaches:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.tableView.rowHeight = 90;
	self.tableView.estimatedRowHeight = 90;
	self.tableView.separatorInset = UIEdgeInsetsZero;
	
	// ImageLoader を用意、デフォルトキャッシュを使用。
	self.imageLoader = [[USGImageLoader alloc] initWithCache:nil delegate:self];
	self.imageLoader.cancelsWhenMemoryWarning = YES;
	
	// 画像の URL を用意
	self.URLs = @[].mutableCopy;
	for (int i=0; i<200; i++) {
		[self.URLs addObject:[NSURL URLWithString:[NSString stringWithFormat:@"http://lorempixel.com/180/180/food/image%d", i]]];
	}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
	// メモリ警告時に通信がキャンセルされるので再開する
	[self __loadVisibleImages];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self __loadVisibleImages];
}
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.imageLoader cancelAllTasks];
}

- (IBAction)clearCaches:(id)sender
{
	[[self.imageLoader imageCache] removeAllObjects];
	[self.tableView reloadData];
	[self __loadVisibleImages];
}


#pragma mark -

/// 表示中セルの画像をロード、画面外のタスクはキャンセル
- (void)__loadVisibleImages
{
	NSMutableArray *URLs = @[].mutableCopy;
	[self.tableView.indexPathsForVisibleRows enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
		[URLs addObject:self.URLs[indexPath.row]];
	}];
	
	[self.imageLoader loadImages:URLs];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.URLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"cell";
	TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.separatorInset = UIEdgeInsetsZero;
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.text = [NSString stringWithFormat:@"#%ld", (long)indexPath.row];
	cell.image = nil;
	
	// 表示するセルの画像をロード、既存のタスクはキャンセルしない
	NSURL *URL = self.URLs[indexPath.row];
	[self.imageLoader loadImagesAppendingTasks:@[URL]];
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	// 画面から消えたセルの画像ロードをキャンセル
	NSURL *URL = self.URLs[indexPath.row];
	[self.imageLoader cancelTasks:@[URL]];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	// こちらでも良い
	//[self __loadVisibleImages];
}


#pragma mark - USGImageLoaderDelegate

- (void)imageLoader:(USGImageLoader*)imageLoader didFinishLoadingImage:(UIImage*)image
				URL:(NSURL*)URL
		  fromCache:(BOOL)fromCache
			  error:(nullable NSError*)error
{
	NSUInteger index = [self.URLs indexOfObject:URL];
	TableViewCell *cell = (TableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	cell.image = image;
}

@end
