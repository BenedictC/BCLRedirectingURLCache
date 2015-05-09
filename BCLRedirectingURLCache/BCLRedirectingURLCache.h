//
//  BCLRedirectingURLCache.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol BCLNonCachingHTTPConnectionService <NSObject>

-(void)sendSynchronousURLRequest:(NSURLRequest *)request completionHandler:(void(^)(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end



@interface BCLRedirectingURLCache : NSURLCache

-(instancetype)initWithParentCache:(NSURLCache *)parentCache rewriteRulesPath:(NSString *)rewriteRulesPath resourceRootPath:(NSString *)resourceRootPath defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler NS_DESIGNATED_INITIALIZER;

@property(atomic, readonly) NSURLCache *parentCache;

@property(atomic, readonly) NSString *rewriteRulesPath;
@property(atomic, readonly) NSString *resourceRootPath;
@property(atomic, readonly) NSCachedURLResponse *(^defaultResponseHandler)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper);

@end
