//
//  AssetDownloadOperation.m
//  AssetsDownloader
//
//  Created by Sandeep Aggarwal on 21/05/17.
//  Copyright © 2017 Sandeep Aggarwal. All rights reserved.
//

#import "AssetDownloadOperation.h"
#import <UIKit/UIKit.h>
#import "AssetCache.h"

typedef NSMutableDictionary<NSString *, id> AssetDownloadCallbackDictionary;

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface AssetDownloadOperation ()

@property (strong, nonatomic, nonnull) NSMutableArray<AssetDownloadCallbackDictionary*> *callbackBlocks;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (strong, nonatomic, nullable) NSMutableData *assetData;

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;
// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;

@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;

@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;


@end

@implementation AssetDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;


- (instancetype)init
{
    return [self initWithRequest:nil inSession:nil options:0];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(AssetDownloaderOptions)options
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    _request = [request copy];
    _options = options;
    _callbackBlocks = [NSMutableArray new];
    _executing = NO;
    _finished = NO;
    _unownedSession = session;
    _barrierQueue = dispatch_queue_create("com.SA.AssetDownloaderOperationBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    
    return self;
}

- (id)addHandlersForCompletion:(AssetDownloaderCompletedBlock)completedBlock
{
    AssetDownloadCallbackDictionary *callbacks = [NSMutableDictionary new];
    if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
    dispatch_barrier_async(self.barrierQueue, ^
    {
        [self.callbackBlocks addObject:callbacks];
    });
    return callbacks;
}

- (nullable NSArray<id> *)callbacksForKey:(NSString *)key
{
    __block NSMutableArray<id> *callbacks = nil;
    dispatch_sync(self.barrierQueue, ^
    {
        // We need to remove [NSNull null] because there might not always be a progress block for each callback
        callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
        [callbacks removeObjectIdenticalTo:[NSNull null]];
    });
    return [callbacks copy];    // strip mutability here
}

- (BOOL)cancel:(nullable id)token
{
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^
    {
        [self.callbackBlocks removeObjectIdenticalTo:token];
        if (self.callbackBlocks.count == 0)
        {
            shouldCancel = YES;
        }
    });
    if (shouldCancel)
    {
        [self cancel];
    }
    return shouldCancel;
}

- (void)start
{
    @synchronized (self)
    {
        if (self.isCancelled)
        {
            self.finished = YES;
            [self reset];
            return;
        }
        
       
        __weak __typeof__ (self) wself = self;
        UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
        self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^
        {
            __strong __typeof (wself) sself = wself;
            
            if (sself)
            {
                [sself cancel];
                
                [app endBackgroundTask:sself.backgroundTaskId];
                sself.backgroundTaskId = UIBackgroundTaskInvalid;
            }
        }];
        
        
        NSURLSession *session = self.unownedSession;
        if (!self.unownedSession)
        {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self
                                                         delegateQueue:nil];
            session = self.ownedSession;
        }
        
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
    }
    
    [self.dataTask resume];
    
    if (!self.dataTask)
    {
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}]];
    }
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid)
    {
        UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }

}

- (void)cancel
{
    @synchronized (self)
    {
        [self cancelInternal];
    }
}

- (void)cancelInternal
{
    if (self.isFinished) return;
    [super cancel];
    
    if (self.dataTask)
    {
        [self.dataTask cancel];
        
        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset
{
    dispatch_barrier_async(self.barrierQueue, ^
    {
        [self.callbackBlocks removeAllObjects];
    });
    self.dataTask = nil;
    self.assetData = nil;
    if (self.ownedSession)
    {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    //'304 Not Modified' is an exceptional one
    if (![response respondsToSelector:@selector(statusCode)] || (((NSHTTPURLResponse *)response).statusCode < 400 && ((NSHTTPURLResponse *)response).statusCode != 304))
    {
        NSInteger expected = (NSInteger)response.expectedContentLength;
        expected = expected > 0 ? expected : 0;

        self.assetData = [[NSMutableData alloc] initWithCapacity:expected];
        self.response = response;
    }
    else
    {
        NSUInteger code = ((NSHTTPURLResponse *)response).statusCode;
        
        //This is the case when server returns '304 Not Modified'. It means that remote asset is not changed.
        //In case of 304 we need just cancel the operation and return cached asset from the cache.
        if (code == 304)
        {
            [self cancelInternal];
        }
        else
        {
            [self.dataTask cancel];
        }
        
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:((NSHTTPURLResponse *)response).statusCode userInfo:nil]];
        
        [self done];
    }
    
    if (completionHandler)
    {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.assetData appendData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    NSCachedURLResponse *cachedResponse = proposedResponse;
    
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData)
    {
        // Prevents caching of responses
        cachedResponse = nil;
    }
    if (completionHandler)
    {
        completionHandler(cachedResponse);
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized(self)
    {
        self.dataTask = nil;
    }
    
    if (error)
    {
        [self callCompletionBlocksWithError:error];
    }
    else
    {
        if ([self callbacksForKey:kCompletedCallbackKey].count > 0)
        {
            if (self.assetData)
            {
                 [self callCompletionBlocksWithAssetData:self.assetData error:nil finished:YES];
            }
            else
            {
               [self callCompletionBlocksWithError:[NSError errorWithDomain:@"com.SA.AssetDownloaderDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Asset data is nil"}]];
            }
        }
    }
    [self done];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    if (completionHandler)
    {
        completionHandler(disposition, credential);
    }
}


- (void)callCompletionBlocksWithError:(nullable NSError *)error
{
    [self callCompletionBlocksWithAssetData:nil error:error finished:YES];
}

- (void)callCompletionBlocksWithAssetData:(nullable NSData *)assetData
                                error:(nullable NSError *)error
                             finished:(BOOL)finished
{
    NSArray<id> *completionBlocks = [self callbacksForKey:kCompletedCallbackKey];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        for (AssetDownloaderCompletedBlock completedBlock in completionBlocks)
        {
            completedBlock(assetData, error, finished);
        }
    });
}



@end
