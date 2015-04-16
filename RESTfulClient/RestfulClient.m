//
//  RestfulClient.m
//  LocoShop
//
//  Created by Olarn U. on 4/4/2558 BE.
//  Copyright (c) 2558 Boomphaw Co., Ltd. All rights reserved.
//

#import "RestfulClient.h"
#import "Reachability.h"

@interface RestfulClient ()

@property (nonatomic, strong) NSMutableData * buffer;
@property (nonatomic) float totalSizeValue;
@property (nonatomic) float downloadingPercentage;
@property (nonatomic, assign) downloadingBlock downloadingBlockCallback;

@end

static Reachability * reachabilityObject;
static BOOL isOnline;

@implementation RestfulClient

- (id)init
{
    self = [super init];
    if (self) {
        
        if (!reachabilityObject) {
            reachabilityObject = [Reachability reachabilityWithHostname:@"www.google.com"];
            reachabilityObject.reachableBlock = ^(Reachability*reach)
            {
                // keep in mind this is called on a background thread
                // and if you are updating the UI it needs to happen
                // on the main thread, like this:
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    isOnline = YES;
                });
            };

            reachabilityObject.unreachableBlock = ^(Reachability*reach)
            {
                isOnline = NO;
            };
            
            // Start the notifier, which will cause the reachability object to retain itself!
            [reachabilityObject startNotifier];
        }
    }
    return self;
}

- (void)httpGetFromUrl:(NSString *)urlString
        onOfflineBlock:(isOfflineBlock)offlineBlock
      downloadingBlock:(downloadingBlock)downloadingBlock
   withCompletionBlock:(completionBlock)completionBlock
            errorBlock:(errorBlock)errorBlock
{
    if (!isOnline) {
        offlineBlock();
        return;
    }
    
    self.downloadingBlockCallback = downloadingBlock;

    NSURL * url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration * defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                 delegate:self
                                                            delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask * task;
    

    task = [session dataTaskWithURL:url
                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                      if (error) {
                          errorBlock(error);
                          return;
                      }
                      

                      NSError * convertError;
                      NSDictionary * result = [NSJSONSerialization JSONObjectWithData:data
                                                                              options:0
                                                                                error:&convertError];
                      if (convertError) {
                          errorBlock(convertError);
                          return;
                      }
                      
                      completionBlock(result);
                  }];
    [task resume];
}

- (void)httpPostFromUrl:(NSString *)urlString
               withData:(NSDictionary *)postData
         onOfflineBlock:(isOfflineBlock)offlineBlock
       downloadingBlock:(downloadingBlock)downloadingBlock
    withCompletionBlock:(completionBlock)completionBlock
             errorBlock:(errorBlock)errorBlock
{
    if (!isOnline) {
        offlineBlock();
        return;
    }

    NSError * convertError;
    NSData * data = [NSJSONSerialization dataWithJSONObject:postData
                                                    options:0
                                                      error:&convertError];
    if (convertError) {
        errorBlock(convertError);
        return;
    }
    
    self.downloadingBlockCallback = downloadingBlock;

    NSURL * url = [NSURL URLWithString:urlString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:10];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    
    NSURLSessionConfiguration * defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask * task;
    task = [session dataTaskWithRequest:request
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                          
                          if (error) {
                              errorBlock(error);
                              return;
                          }
                          
                          NSError * convertError2;
                          
                          if (data && [data length] > 0) {
                              NSDictionary * result = [NSJSONSerialization JSONObjectWithData:data
                                                                                      options:0
                                                                                        error:&convertError2];
                              if (convertError) {
                                  errorBlock(convertError);
                                  return;
                              }
                              completionBlock(result);
                          }

                      }];
    [task resume];
}

#pragma mark - NSURLSessionDataDelegate Handlers

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    
    self.totalSizeValue = [response expectedContentLength];
    self.buffer = [[NSMutableData alloc]init];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.buffer appendData:data];
    self.downloadingPercentage = [self.buffer length ] / self.totalSizeValue;
    
    if (self.downloadingBlockCallback) {
        self.downloadingBlockCallback(self.totalSizeValue, self.downloadingPercentage);
    }
}

@end
