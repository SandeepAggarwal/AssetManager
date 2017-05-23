//
//  AssetImageParser.m
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 23/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetImageParser.h"
#import <UIKit/UIKit.h>

@implementation AssetImageParser

- (id)parseData:(NSData *)data
{
    if (!data)
    {
        return nil;
    }
    
    return [UIImage imageWithData:data];
}

@end
