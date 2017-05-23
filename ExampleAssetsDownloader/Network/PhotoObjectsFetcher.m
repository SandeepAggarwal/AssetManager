//
//  PhotoObjectsFetcher.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "PhotoObjectsFetcher.h"
#import "AssetManager.h"

@interface PhotoObjectsFetcher ()

@property (nonatomic, strong) NSURL* url;

@end

@implementation PhotoObjectsFetcher

- (instancetype)init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    self.url = [NSURL URLWithString:@"http://pastebin.com/raw/wgkJgazE"];
    
    return self;
}

#pragma mark - <Public Methods>

- (void)fetchPhotosWithOffset:(NSInteger)offset count:(NSInteger)count completionBlock:(PhotoObjectsFetcherResultBlock)block
{
    AssetManager* manager = [AssetManager sharedManager];
    [manager loadAssetType:(AssetJSON) WithURL:self.url options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
    {
        if (!block)
        {
            return;
        }
        
        if (error)
        {
            block(nil, error);
        }
        else
        {
            block([self photoObjectsFromResponse:asset], nil);
        }
        
    }];
}

#pragma mark - <Private Methods>

- (NSArray<Photo *> *)photoObjectsFromResponse:(NSArray *)jsonResponse
{
    NSMutableArray* photoObjects = [NSMutableArray new];
    for (NSDictionary* object  in jsonResponse)
    {
        Photo* photo = [Photo new];
        photo._id = [object valueForKey:@"id"];
        photo.width = [[object valueForKey:@"width"] floatValue];
        photo.height = [[object valueForKey:@"height"] floatValue];
        photo.url = [NSURL URLWithString:[[object valueForKey:@"urls"] valueForKey:@"regular"]];
        [photoObjects addObject:photo];
    }
    
    return photoObjects;
}

@end
