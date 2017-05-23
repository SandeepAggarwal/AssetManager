//
//  AssetJSONParser.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 23/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetJSONParser.h"

@implementation AssetJSONParser

- (id)parseData:(NSData *)data
{
    if (!data)
    {
        return nil;
    }
    
    NSError *jsonError;
    NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError)
    {
        return nil;
    }
    return jsonResponse;
}

@end
