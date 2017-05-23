//
//  AssetDownloader.m
//  AssetsDownloader
//
//  Created by Sandeep Aggarwal on 21/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetDownloader.h"
#import "AssetDownloadOperation.h"

@implementation AssetDownloaderToken
@end

@interface AssetDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (strong, nonatomic) NSMutableDictionary<NSURL *, AssetDownloadOperation *> *URLOperations;

// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (strong, nonatomic) dispatch_queue_t barrierQueue;

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation AssetDownloader

#pragma mark - Initialization

+ (nonnull instancetype)sharedDownloader
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^
    {
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init
{
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration
{
    if (!self)
    {
        return nil;
    }
    
    _downloadQueue = [NSOperationQueue new];
    _downloadQueue.maxConcurrentOperationCount = 6;
    _downloadQueue.name = @"com.SA.AssetsDownloader";
    _URLOperations = [NSMutableDictionary new];
    _barrierQueue = dispatch_queue_create("com.SA.AssetsDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    
    _downloadTimeout = 10;
    sessionConfiguration.timeoutIntervalForRequest = _downloadTimeout;
    
    /**
     *  Create the session for this task
     *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
     *  method calls and completion handler calls.
     */
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
    
    return self;
}

#pragma mark - Public methods

- (AssetDownloaderToken *)downloadAssetType:(id<AssetType>)assetType WithURL:(NSURL *)url options:(AssetDownloaderOptions)options completed:(AssetDownloaderCompletedBlock)completedBlock
{
    __weak typeof(self) wself = self;
    
    /*
     This will ensure the same asset may be requested by multiple sources simultaneously (even before it has loaded), and if one of the sources cancels the load, it should not affect the remaining requests
     */
    return [self addCompletedBlock:completedBlock forURL:url createCallback:^AssetDownloadOperation *
    {
        NSLog(@"downloading: %@",url);
        __strong __typeof (wself) sself = wself;
        NSTimeInterval timeoutInterval = sself.downloadTimeout;
        if (timeoutInterval == 0.0)
        {
            timeoutInterval = 15.0;
        }
        
        NSURLRequestCachePolicy cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        if (options & AssetDownloaderNoCache)
        {
            cachePolicy = NSURLRequestReturnCacheDataDontLoad;
        }
        else
        {
            cachePolicy = NSURLRequestUseProtocolCachePolicy;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
        request.HTTPShouldUsePipelining = YES;
        
        AssetDownloadOperation *operation = [[AssetDownloadOperation alloc] initWithRequest:request inSession:sself.session options:options];
        operation.queuePriority = NSOperationQueuePriorityHigh;
        [sself.downloadQueue addOperation:operation];
        
        return operation;
    }];
}

- (void)cancel:(AssetDownloaderToken *)token
{
    dispatch_barrier_async(self.barrierQueue, ^
    {
        AssetDownloadOperation *operation = self.URLOperations[token.url];
        BOOL canceled = [operation cancel:token.downloadOperationCancelToken];
        if (canceled)
        {
            [self.URLOperations removeObjectForKey:token.url];
        }
    });
}

#pragma mark Helper methods

- (AssetDownloadOperation *)operationWithTask:(NSURLSessionTask *)task
{
    AssetDownloadOperation *returnOperation = nil;
    for (AssetDownloadOperation *operation in self.downloadQueue.operations)
    {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier)
        {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    // Identify the operation that runs this task and pass it the delegate method
    AssetDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    
    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    // Identify the operation that runs this task and pass it the delegate method
    AssetDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    
    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    
    // Identify the operation that runs this task and pass it the delegate method
    AssetDownloadOperation *dataOperation = [self operationWithTask:dataTask];
    
    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // Identify the operation that runs this task and pass it the delegate method
    AssetDownloadOperation *dataOperation = [self operationWithTask:task];
    
    [dataOperation URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    // Identify the operation that runs this task and pass it the delegate method
    AssetDownloadOperation *dataOperation = [self operationWithTask:task];
    
    [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

#pragma mark - Private Methods

- (AssetDownloaderToken *)addCompletedBlock:(AssetDownloaderCompletedBlock)completedBlock
                                                   forURL:(nullable NSURL *)url
                                           createCallback:(AssetDownloadOperation *(^)())createCallback
{
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no data.
    if (url == nil)
    {
        if (completedBlock != nil)
        {
            completedBlock(nil, nil, NO);
        }
        return nil;
    }
    
    __block AssetDownloaderToken *token = nil;
    
    dispatch_barrier_sync(self.barrierQueue, ^
    {
        AssetDownloadOperation *operation = self.URLOperations[url];
        if (!operation)
        {
            operation = createCallback();
            self.URLOperations[url] = operation;
            
            __weak AssetDownloadOperation *woperation = operation;
            operation.completionBlock = ^
            {
                AssetDownloadOperation *soperation = woperation;
                if (!soperation) return;
                if (self.URLOperations[url] == soperation)
                {
                    [self.URLOperations removeObjectForKey:url];
                };
            };
        }
        id downloadOperationCancelToken = [operation addHandlersForCompletion:completedBlock];
        
        token = [AssetDownloaderToken new];
        token.url = url;
        token.downloadOperationCancelToken = downloadOperationCancelToken;
    });
    
    return token;
}

#pragma mark - dealloc

- (void)dealloc
{
    [self.session invalidateAndCancel];
    self.session = nil;
    
    [self.downloadQueue cancelAllOperations];
}

@end
