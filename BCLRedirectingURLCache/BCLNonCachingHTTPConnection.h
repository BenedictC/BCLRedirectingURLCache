//
//  BCLNonCachingHTTPConnection.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCLNonCachingHTTPConnection : NSObject

+(void)sendSynchronousURLRequest:(NSURLRequest *)request completionHandler:(void(^)(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error))completionHandler;

-(instancetype)initWithURLRequest:(NSURLRequest *)request NS_DESIGNATED_INITIALIZER;
@property(atomic, readonly) NSURLRequest *URLRequest;

-(void)sendSynchronously:(void(^)(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
