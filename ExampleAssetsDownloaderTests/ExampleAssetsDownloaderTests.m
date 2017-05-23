//
//  ExampleAssetsDownloaderTests.m
//  ExampleAssetsDownloaderTests
//
//  Created by Sandeep Aggarwal on 20/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AssetManager.h"
#import "AssetCache.h"

@interface ExampleAssetsDownloaderTests : XCTestCase

@end

@implementation ExampleAssetsDownloaderTests

- (void)testJSONDownloading
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"JSON downloads"];
    
    AssetManager* manager = [AssetManager sharedManager];
    NSURL* url = [NSURL URLWithString:@"http://pastebin.com/raw/wgkJgazE"];
    [manager loadAssetType:(AssetJSON) WithURL:url options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
     {
         if (asset && data && !error && finished)
         {
             [expectation fulfill];
         }
         else
         {
             XCTFail(@"Something went wrong");
         }
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testJSONCaching
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"JSON Caches"];
    
    AssetManager* manager = [AssetManager sharedManager];
    NSURL* url = [NSURL URLWithString:@"http://pastebin.com/raw/wgkJgazE"];
    [manager loadAssetType:(AssetJSON) WithURL:url options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
     {
         if (asset && data && !error && finished)
         {
            NSString* cacheKey = [manager cacheKeyForURL:url];
            NSData* cacheData = [[AssetCache sharedAssetCache] assetDataFromMemoryCacheForKey:cacheKey];
             if (cacheData && [cacheData isEqual:data])
             {
                [expectation fulfill];
             }
             else
             {
                 XCTFail(@"Something went wrong");
             }
         }
         else
         {
             XCTFail(@"Something went wrong");
         }
     }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCancelOperation
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel"];
    
    AssetManager* manager = [AssetManager sharedManager];
    NSURL *imageURL = [NSURL URLWithString:@"https://images.unsplash.com/photo-1464550883968-cec281c19761?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=1080&fit=max&s=1881cd689e10e5dca28839e68678f432"];
    AssetDownloaderToken* token = [manager loadAssetType:(AssetImage) WithURL:imageURL options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
     {
         XCTFail(@"Should not get here");
    }];
    
    [manager cancelDownloadOperationWithToken:token];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
}

- (void)testThatDownloadingSameURLTwiceAndCancellingFirstWorks
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    
    AssetManager* manager = [AssetManager sharedManager];
    NSURL *imageURL = [NSURL URLWithString:@"https://images.unsplash.com/photo-1464550883968-cec281c19761?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&w=1080&fit=max&s=1881cd689e10e5dca28839e68678f432"];
    
    AssetDownloaderToken *token1 = [manager
                                    loadAssetType:(AssetImage) WithURL:imageURL options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
                                       {
                                           XCTFail(@"Shouldn't have completed here.");
                                       }];
    
    
    [manager loadAssetType:(AssetImage) WithURL:imageURL options:(AssetDownloaderCache) completed:^(id asset, NSData *data, NSError *error, BOOL finished, NSURL *assetURL)
    {
        if (asset && data && !error && finished)
        {
            [expectation fulfill];
        }
        else
        {
            XCTFail(@"Something went wrong");
        }
    }];
    
    [manager cancelDownloadOperationWithToken:token1];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
