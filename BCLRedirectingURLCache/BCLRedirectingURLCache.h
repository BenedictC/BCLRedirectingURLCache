//
//  BCLRedirectingURLCache.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol BCLNonCachingHTTPConnectionService <NSObject>

-(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end



@interface BCLRedirectingURLCache : NSURLCache

+(instancetype)cacheWithParentCache:(NSURLCache *)parentCache rewriteRulesMainBundleFileName:(NSString *)fileName defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler;
+(instancetype)cacheWithParentCache:(NSURLCache *)parentCache rewriteRulesPath:(NSString *)rewriteRulesPath resourceRootPath:(NSString *)resourceRootPath defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultHandler;
-(instancetype)initWithParentCache:(NSURLCache *)parentCache rewriteRules:(NSArray *)rewriteRules defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultHandler NS_DESIGNATED_INITIALIZER;

@property(atomic, readonly) NSURLCache *parentCache;

@property(atomic, readonly) NSArray *rewriteRules;
@property(atomic, readonly) NSCachedURLResponse *(^defaultResponseHandler)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper);

@end
