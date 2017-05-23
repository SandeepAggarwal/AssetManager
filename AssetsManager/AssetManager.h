//
//  AssetManager.h
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 22/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetDownloader.h"
#import "AssetDownloadOperation.h"
#import "AssetCache.h"

/**
 To handle more asset types, just add more options to this enum and confirm to protocol 'AssetType'
 */
typedef NS_ENUM(NSInteger, Asset)
{
    AssetImage = 0,
    AssetJSON
};

typedef void(^AssetDataCheckCacheCompletionBlock)(BOOL isInCache);
typedef void(^AssetDataCompletionBlock)(id asset, NSData * data, NSError *error, BOOL finished, NSURL *assetURL);

@interface AssetManager : NSObject

+ (instancetype)sharedManager;

- (AssetDownloaderToken *)loadAssetType:(Asset)asset WithURL:(NSURL *)url options:(AssetDownloaderOptions)options completed:(AssetDataCompletionBlock)completedBlock;

- (void)cancelDownloadOperationWithToken:(AssetDownloaderToken *)token;


/**
 *Return the cache key for a given URL
 */
- (NSString *)cacheKeyForURL:(NSURL *)url;

@end
