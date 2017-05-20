//
//  PhotoObjectsFetcher.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "PhotoObjectsFetcher.h"

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
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[session dataTaskWithURL:self.url
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
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
            block([self photoObjectsFromResponse:data], nil);
        }
    }] resume];
}

#pragma mark - <Private Methods>

- (NSArray<Photo *> *)photoObjectsFromResponse:(NSData *)data
{
    NSError *jsonError;
    NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError)
    {
        return nil;
    }
    
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
