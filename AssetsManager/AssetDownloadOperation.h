//
//  AssetDownloadOperation.h
//  AssetsDownloader
//
//  Created by Sandeep Aggarwal on 21/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssetDownloader.h"

@interface AssetDownloadOperation : NSOperation<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

/**
 * The request used by the operation's task.
 */
@property (strong, nonatomic, readonly) NSURLRequest *request;

/**
 * The operation's task
 */
@property (strong, nonatomic, readonly) NSURLSessionTask *dataTask;


/**
 * The AssetDownloaderOptions for the receiver.
 */
@property (assign, nonatomic, readonly) AssetDownloaderOptions options;

/**
 * The response returned by the operation's connection.
 */
@property (strong, nonatomic) NSURLResponse *response;

/**
 *  Initializes a `AssetDownloadOperation` object
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *  @param options        downloader options
 *
 *  @return the initialized instance
 */
- (instancetype)initWithRequest:(NSURLRequest *)request
                              inSession:(NSURLSession *)session
                                options:(AssetDownloaderOptions)options;

/**
 *  Adds handlers for completion. Returns a token that can be passed to -cancel: to cancel the callbacks.
 *
 *  @param completedBlock the block executed when the download is done.
 *                        @note the completed block is executed on the main queue for success. If errors are found, there is a chance the block will be executed on a background queue
 *
 *  @return the token to use to cancel completedBlocks
 */
- (id)addHandlersForCompletion:(AssetDownloaderCompletedBlock)completedBlock;

/**
 *  Cancels a set of callbacks. Once all callbacks are canceled, the operation is cancelled.
 *
 *  @param token the token representing a set of callbacks to cancel
 *
 *  @return YES if the operation was stopped because this was the last token to be canceled. NO otherwise.
 */
- (BOOL)cancel:(id)token;

@end
