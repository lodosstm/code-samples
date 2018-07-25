//
//  NetworkRequestSender.h
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkRequestSender : NSObject

+ (void)sendToEndpoint:(NSString *)endpoint
            queryItems:(NSArray *)queryItems
                  body:(NSData *)body
        HTTPmethodType:(NSString *)HTTPmethodType
               success:(void (^)(NSData *data))successBlock
                 error:(void (^)(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict))errorBlock
               cleanup:(void (^)())cleanupBlock;

+ (void)uploadToEndpoint:(NSString *)endpoint
              queryItems:(NSArray *)queryItems
                    body:(NSData *)body
          HTTPmethodType:(NSString *)HTTPmethodType
     delegateForProgress:(id <NSURLSessionDelegate>)delegateForProgress
                 success:(void (^)(NSData *data))successBlock
                   error:(void (^)(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict))errorBlock
                 cleanup:(void (^)())cleanupBlock;

@end
