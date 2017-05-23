//
//  AssetManager.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 22/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetManager.h"

#import "AssetImageParser.h"
#import "AssetJSONParser.h"

@interface AssetManager ()

@property (strong, nonatomic, readwrite, nonnull) AssetCache *assetCache;
@property (strong, nonatomic, readwrite, nonnull) AssetDownloader *assetDownloader;

@end

@implementation AssetManager

+ (nonnull instancetype)sharedManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^
    {
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init
{
    AssetCache *cache = [AssetCache sharedAssetCache];
    AssetDownloader *downloader = [AssetDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

- (nonnull instancetype)initWithCache:(nonnull AssetCache *)cache downloader:(nonnull AssetDownloader *)downloader
{
    if (!self)
    {
        return nil;
    }

    _assetCache = cache;
    _assetDownloader = downloader;
    
    return self;
}

- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url
{
    if (!url)
    {
        return @"";
    }
    
    return url.absoluteString;
}

- (void)cachedAssetExistsForURL:(nullable NSURL *)url
                     completion:(nullable AssetDataCheckCacheCompletionBlock)completionBlock
{
    NSString *key = [self cacheKeyForURL:url];
    
    BOOL isInMemoryCache = ([self.assetCache assetDataFromMemoryCacheForKey:key] != nil);
    
    if (isInMemoryCache)
    {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^
        {
            if (completionBlock)
            {
                completionBlock(YES);
            }
        });
        return;
    }
}

- (void)cancelDownloadOperationWithToken:(AssetDownloaderToken *)token
{
    if (!token)
    {
        return;
    }
    
    [self.assetDownloader cancel:token];
}

- (AssetDownloaderToken *)loadAssetType:(Asset)asset WithURL:(NSURL *)url options:(AssetDownloaderOptions)options completed:(AssetDataCompletionBlock)completedBlock
{
    id<AssetType> assetType;
    switch (asset)
    {
        case AssetImage:
            assetType = [AssetImageParser new];
            break;
            
        case AssetJSON:
            assetType = [AssetJSONParser new];
        
        break;
            
        default:
            break;
    }
    
    return [self loadAssetDataType:assetType WithURL:url options:options completed:completedBlock];
}


#pragma mark - Private Methods


- (AssetDownloaderToken *)loadAssetDataType:(id<AssetType>)assetType WithURL:(NSURL *)url options:(AssetDownloaderOptions)options completed:(AssetDataCompletionBlock)completedBlock
{
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class])
    {
        url = nil;
    }
    
    NSString *key = [self cacheKeyForURL:url];
    NSData* cachedAssetData = [self.assetCache assetDataFromMemoryCacheForKey:key];
    if (cachedAssetData.length > 0)
    {
        completedBlock([self convertIntoAssetType:assetType FromData:cachedAssetData], cachedAssetData, nil, YES, url);
        return nil;
    }
    
    AssetDownloaderOptions downloaderOptions = 0;
    if (options & AssetDownloaderCache)
    {
        downloaderOptions |= AssetDownloaderCache;
    }
    
    AssetDownloaderToken *operationToken = [self.assetDownloader downloadAssetType:assetType WithURL:url options:options completed:^(NSData *data, NSError *error, BOOL finished)
                                            {
                                                if (error)
                                                {
                                                    completedBlock(nil, nil,error,YES, url);
                                                    return;
                                                }
                                                else
                                                {
                                                    if (data.length == 0)
                                                    {
                                                        completedBlock(nil, nil, nil, YES, url);
                                                        return;
                                                    }
                                                    
                                                    id asset = [self convertIntoAssetType:assetType FromData:data];
                                                    if (options & AssetDownloaderCache)
                                                    {
                                                        [self.assetCache storeAssetData:data forKey:key completion:^
                                                         {
                                                             completedBlock(asset, data, nil, YES, url);
                                                             return;
                                                         }];
                                                    }
                                                    else
                                                    {
                                                        completedBlock(asset, data, nil, YES, url);
                                                        return;
                                                    }
                                                }
                                            }];
    
    return operationToken;
}

- (id)convertIntoAssetType:(id<AssetType>)assetType FromData:(NSData*)data
{
    return [assetType parseData:data];
}

@end
