//
//  NetworkRequestSender.m
//
//  Copyright © 2015 Lodossteam. All rights reserved.
//

#import "NetworkRequestSender.h"
#import "Consts.h"
#import "NSString+Extensions.h"
#import "CurrentUserSession.h"
#import "UIHelper.h"

@implementation NetworkRequestSender

+ (void)sendToEndpoint:(NSString *)endpoint
            queryItems:(NSArray *)queryItems
                  body:(NSData *)body
        HTTPmethodType:(NSString *)HTTPmethodType
               success:(void (^)(NSData *data))successBlock
                 error:(void (^)(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict))errorBlock
               cleanup:(void (^)())cleanupBlock {
    NSAssert((![NSString isNilOrEmpty:endpoint]), kAssertMessageFormat, __PRETTY_FUNCTION__, @"endpoint");
    
    if ([NSString isNilOrEmpty:endpoint]) return;
    
    NSString *fullURLAsString = [NSString stringWithFormat:@"%@%@", [self serverURL], endpoint];
    NSMutableURLRequest *request = [NetworkRequestSender mutableURLRequestWithURL:fullURLAsString queryItems:queryItems body:body];
    request.HTTPMethod = HTTPmethodType;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task;
    task = [session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                          [NetworkRequestSender handleRequestAnswerWith:data
                                                                               response:response
                                                                                  error:error
                                                                                success:successBlock
                                                                                  error:errorBlock
                                                                                cleanup:cleanupBlock];
                                      }];
    [task resume];
}

+ (void)uploadToEndpoint:(NSString *)endpoint
              queryItems:(NSArray *)queryItems
                    body:(NSData *)body
          HTTPmethodType:(NSString *)HTTPmethodType
    delegateForProgress:(id <NSURLSessionDelegate>)delegateForProgress
                success:(void (^)(NSData *data))successBlock
                  error:(void (^)(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict))errorBlock
                cleanup:(void (^)())cleanupBlock {
    NSAssert((![NSString isNilOrEmpty:endpoint]), kAssertMessageFormat, __PRETTY_FUNCTION__, @"endpoint");
    
    if ([NSString isNilOrEmpty:endpoint]) return;
    
    NSString *fullURLAsString = [NSString stringWithFormat:@"%@%@", [self serverURL], endpoint];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:fullURLAsString];
    if (queryItems != nil)
        if ([queryItems count] > 0) {
            components.queryItems = queryItems;
        }
    NSURL *URL = components.URL;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [request setHTTPMethod:kPOST];
    request.HTTPBody = body;
    
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Accept"        : @"application/json",
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                                   };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:delegateForProgress delegateQueue:nil];
    
    NSURLSessionDataTask *task;
    task = [session dataTaskWithRequest:request
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSError *parseError = nil;
                NSDictionary *resonseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                NSLog(@" ### uploadToEndpoint 1 ##### %@ ######", resonseDict);
                
                [NetworkRequestSender handleRequestAnswerWith:data
                                                     response:response
                                                        error:error
                                                      success:successBlock
                                                        error:errorBlock
                                                      cleanup:cleanupBlock];
            }];
    
    [task resume];
}

+ (void)handleRequestAnswerWith:(NSData *)data
                       response:(NSURLResponse *)response
                          error:(NSError *)error
                        success:(void (^)(NSData *data))successBlock
                          error:(void (^)(NSString *errorDescriptionText, NSInteger HTTPstatusCode, NSString *serverErrorCode, NSDictionary *serverResponseDict))errorBlock
                        cleanup:(void (^)())cleanupBlock {
    if (!error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            if (kNetworkLoggingCalls) NSLog(@"* | HTTP: %ld | * URL: %@\n", (long)[(NSHTTPURLResponse *)response statusCode], response.URL);
            NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (kNetworkLoggingResponses) NSLog(@"*** Response Body:\n%@\n", responseData);
            
            NSInteger HTTPstatusCode = [(NSHTTPURLResponse *)response statusCode];
            
            NSError *parseError = nil;
            
            BOOL isSuccessResponseCodeIs = (HTTPstatusCode == 200);
            if (isSuccessResponseCodeIs) {
                if (successBlock) successBlock(data);
            } else {
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if (errorBlock) errorBlock(errorString, HTTPstatusCode, errosDict[@"code"], errosDict);
            }
        } else
            if (kNetworkLoggingCalls) NSLog(@"*** URL: %@", response.URL);
    } else {
        if (kNetworkLoggingResponses) NSLog(@" ### SERVER : error localizedDescription : %@", error.localizedDescription);
        if (kNetworkLoggingResponses) NSLog(@" ### error : %@", error);
        
        if (errorBlock) {
            errorBlock(error.localizedDescription, (long)[(NSHTTPURLResponse *)response statusCode], @"", @{});
        }
    }
    
    if (cleanupBlock) cleanupBlock();
}

+ (NSMutableURLRequest *)mutableURLRequestWithURL:(NSString *)URLString queryItems:(NSArray *)queryItems body:(NSData *)body {
    NSMutableURLRequest *request = [NetworkRequestSender defaultMutableURLRequest];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    if (queryItems != nil)
        if ([queryItems count] > 0) {
            components.queryItems = queryItems;
        }
    NSURL *URL = components.URL;
    [request setURL:URL];
    
    [request setHTTPBody:body];
    
    return request;
}

+ (NSMutableURLRequest *)defaultMutableURLRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:kPOST];
    [request setValue:kSessionHTTPValue forHTTPHeaderField:kSessionHTTPHeaderField];
    
    return request;
}

+ (NSString *)serverURL {
    return kServerURL;
}

@end
