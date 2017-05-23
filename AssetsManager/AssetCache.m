//
//  AssetCache.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 22/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetCache.h"
#import <UIKit/UIKit.h>

@interface AutoPurgeCache : NSCache
@end

@implementation AutoPurgeCache

- (nonnull instancetype)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end

@interface AssetCache ()

@property (strong, nonatomic, nonnull) NSCache *memCache;

@end

@implementation AssetCache


+ (nonnull instancetype)sharedAssetCache
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^
    {
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithNamespace:@"default"];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    NSString *fullNamespace = [@"com.SA.AssetDownloaderCache." stringByAppendingString:ns];
    _memCache = [[AutoPurgeCache alloc] init];
    _memCache.name = fullNamespace;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearMemory)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)storeAssetData:(NSData *)data forKey:(NSString *)key completion:(AssetCacheBlock)completionBlock
{
    if (!data || !key)
    {
        if (completionBlock)
        {
            completionBlock();
        }
        return;
    }
    
    [self.memCache setObject:data forKey:key cost:0];
    if (completionBlock)
    {
        completionBlock();
    }
}

- (void)removeAssetForKey:(NSString *)key withCompletion:(AssetCacheBlock)completion
{
    if (key == nil)
    {
        return;
    }
    
    [self.memCache removeObjectForKey:key];
    
    if (completion)
    {
        completion();
    }
}

- (NSData *)assetDataFromMemoryCacheForKey:(NSString *)key
{
    return [self.memCache objectForKey:key];
}

- (void)clearMemory
{
    [self.memCache removeAllObjects];
}


@end
