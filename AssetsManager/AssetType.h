//
//  AssetType.h
//  ExampleAssetsDownloader
//
//  Created by Sandeep Aggarwal on 23/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AssetType <NSObject>

- (id)parseData:(NSData*)data;

@end
