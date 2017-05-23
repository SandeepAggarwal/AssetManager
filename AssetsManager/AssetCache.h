//
//  AssetCache.h
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 22/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AssetCacheBlock)();

@interface AssetCache : NSObject

#pragma mark - Singleton and initialization

/**
 * Returns global shared cache instance
 */
+ (nonnull instancetype)sharedAssetCache;

/**
 * Asynchronously store asset data into memory at the given key.
 *
 * @param data           The data to store
 * @param key             The unique asset cache key, usually it's asset absolute URL
 * @param completionBlock A block executed after the operation is finished
 */
- (void)storeAssetData:(nullable NSData *)data
            forKey:(nullable NSString *)key
        completion:(nullable AssetCacheBlock)completionBlock;

/**
 * Query the memory cache synchronously.
 *
 * @param key The unique key used to store the asset data
 */
- (nullable NSData *)assetDataFromMemoryCacheForKey:(nullable NSString *)key;

/**
 * Remove the asset from memory and disk cache asynchronously
 *
 * @param key             The unique asset cache key
 * @param completion      A block that should be executed after the asset has been removed (optional)
 */
- (void)removeAssetForKey:(nullable NSString *)key withCompletion:(nullable AssetCacheBlock)completion;

/**
 * Clear all memory cached assets
 */
- (void)clearMemory;

@end
