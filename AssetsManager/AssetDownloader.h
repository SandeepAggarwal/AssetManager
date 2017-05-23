//
//  AssetDownloader.h
//  AssetsDownloader
//
//  Created by Sandeep Aggarwal on 21/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetType.h"

typedef NS_ENUM(NSInteger , AssetDownloaderOptions)
{
    /**
     Default Value. Assets will be cached
     */
    AssetDownloaderCache = 1 << 0,
    AssetDownloaderNoCache
};

/**
 *  A token associated with each download. Can be used to cancel a download
 */
@interface AssetDownloaderToken : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) id downloadOperationCancelToken;

@end

typedef void(^AssetDownloaderCompletedBlock)(NSData *data, NSError *error, BOOL finished);

@interface AssetDownloader : NSObject

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 */
+ (instancetype)sharedDownloader;

/**
 * @param assetType      The AssetType to download
 * @param url            The URL to the asset to download
 * @param options        The options to be used for this download
 * @param completedBlock A block called once the download is completed.
 *
 * @return A token (AssetDownloaderToken) that can be passed to -cancel: to cancel this operation
 */
- (AssetDownloaderToken *)downloadAssetType:(id<AssetType>)assetType WithURL:(NSURL *)url
                                                   options:(AssetDownloaderOptions)options
                                                 completed:(AssetDownloaderCompletedBlock)completedBlock;

/**
 *  The timeout value (in seconds) for the download operation. Default: 10.0.
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;

/**
 * Cancels a download that was previously queued using -downloadAssetType:WithURL:options:completed:
 *
 * @param token The token received from -downloadAssetType:WithURL:options:completed: that should be canceled.
 */
- (void)cancel:(AssetDownloaderToken *)token;


@end
