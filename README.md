# USGImageCache
USGImageCache is an asynchronous image downloader with 2-layered caching mechanism for iOS. Written in Objective-C.

- An asynchronous / concurrent image downloader with NSURLSession
- 2-layered image caching, disk and memory caches.
- Customizes concurrent count with NSURLSessionConfiguration
- Tasks are appendable or cancellable when needed. Useful to visible UITableViewCells

# Usage

USGImageCache contains these classes:

- USGImageLoader
- USGImageDownloadManager
- USGImageCache
- USGImageCacheManager
- USGNetworkIndicatorManager

See ViewController.m for examples.

# License

USGImageCache is available under the MIT license. See LICENSE for details.