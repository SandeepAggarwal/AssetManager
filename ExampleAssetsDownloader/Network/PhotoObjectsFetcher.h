//
//  PhotoObjectsFetcher.h
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Photo.h"

typedef void(^PhotoObjectsFetcherResultBlock)(NSArray<Photo *>* photos, NSError* error);

@interface PhotoObjectsFetcher : NSObject

- (void)fetchPhotosWithOffset:(NSInteger)offset count:(NSInteger)count completionBlock:(PhotoObjectsFetcherResultBlock)block;

@end
