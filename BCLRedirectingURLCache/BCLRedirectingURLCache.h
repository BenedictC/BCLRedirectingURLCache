//
//  BCLRedirectingURLCache.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

/*
 
 TODO: Document rewrite file format

 
 */


#import <Foundation/Foundation.h>






@protocol BCLNonCachingHTTPConnectionService <NSObject>

-(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end



@interface BCLRedirectingURLCache : NSURLCache

+(instancetype)cacheWithRewriteRulesFileNamed:(NSString *)fileName defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler;
+(instancetype)cacheWithRewriteRulesPath:(NSString *)rewriteRulesPath resourceRootPath:(NSString *)resourceRootPath defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultHandler;

-(instancetype)initWithRewriteRules:(NSArray *)rewriteRules defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultResponseHandler NS_DESIGNATED_INITIALIZER;

@property(atomic, readonly) NSArray *rewriteRules;
@property(atomic, readonly) NSCachedURLResponse *(^defaultResponseHandler)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper);

@end
