//
//  RestfulClient.h
//  LocoShop
//
//  Created by Olarn U. on 4/4/2558 BE.
//  Copyright (c) 2558 Boomphaw Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^isOfflineBlock)();
typedef void(^downloadingBlock)(float totalSize, float percent);
typedef void(^completionBlock)(NSDictionary * results);
typedef void(^errorBlock)(NSError * error);
                               
@interface RestfulClient : NSObject <NSURLSessionDataDelegate>

- (id)init;

- (void)httpGetFromUrl:(NSString *)urlString
        onOfflineBlock:(isOfflineBlock)offlineBlock
      downloadingBlock:(downloadingBlock)downloadingBlock
   withCompletionBlock:(completionBlock)completionBlock
            errorBlock:(errorBlock)errorBlock;

- (void)httpPostFromUrl:(NSString *)urlString
               withData:(NSDictionary *)postData
         onOfflineBlock:(isOfflineBlock)offlineBlock
       downloadingBlock:(downloadingBlock)downloadingBlock
    withCompletionBlock:(completionBlock)completionBlock
             errorBlock:(errorBlock)errorBlock;

@end
