//
//  BCLRedirectingURLCache.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLRedirectingURLCache.h"
#import "BCLRedirectingURLCacheRedirectionRule.h"
#import "BCLNonCachingHTTPConnection.h"



@implementation BCLRedirectingURLCache

#pragma mark - factory methods
+(instancetype)cacheWithRedirectRulesFileNamed:(NSString *)fileName defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *redirectRulesPath = [bundle pathForResource:fileName ofType:nil];
    NSString *resourceRootPath = [bundle bundlePath];

    return [BCLRedirectingURLCache cacheWithRedirectRulesPath:redirectRulesPath resourceRootPath:resourceRootPath defaultResponseHandler:defaultHandler];
}



+(instancetype)cacheWithRedirectRulesPath:(NSString *)redirectRulesPath resourceRootPath:(NSString *)resourceRootPath defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler
{
    NSURL *baseURL = (redirectRulesPath != nil) ? [NSURL fileURLWithPath:resourceRootPath] : [[NSBundle mainBundle] bundleURL];
    NSArray *redirectRules = [BCLRedirectingURLCacheRedirectionRule redirectRulesFromContentsOfFile:redirectRulesPath baseURL:baseURL];
    return [[self alloc] initWithRedirectRules:redirectRules defaultResponseHandler:defaultHandler];
}



#pragma mark - instance life cycle
-(instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    return [self initWithRedirectRules:nil defaultResponseHandler:NULL];
}



-(instancetype)initWithRedirectRules:(NSArray *)redirectRules defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultResponseHandler
{
    NSParameterAssert(redirectRules || defaultResponseHandler);
    
    self = [super initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];

    if (self == nil) {
        return nil;
    }

    _redirectRules = [redirectRules copy];
    _defaultResponseHandler = defaultResponseHandler;

    return self;
}



#pragma mark - Useful NSURLCache methods
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    //Check the rules
    for (BCLRedirectingURLCacheRedirectionRule *rule in self.redirectRules) {
        NSURL *resolved = [rule resolvedURLForRequest:request];
        if (resolved != nil) {

            NSData *data =
                ([resolved.scheme isEqualToString:@"http"] || [resolved.scheme isEqualToString:@"https"]) ? ({
                    NSMutableURLRequest *secondaryRequest = [request mutableCopy];
                    secondaryRequest.URL = resolved;
                    [BCLNonCachingHTTPConnection sendSynchronousRequest:secondaryRequest returningResponse:NULL error:NULL];
                }) :
                [resolved.scheme isEqualToString:@"file"] ? ({
                    [NSData dataWithContentsOfFile:resolved.path];
                }) :
                nil;

            if (data == nil) {
                //TODO: Is it sensible to log this? What are the alernatives?
                NSLog(@"%@: Unable to load data for redirected URLRequest. Rule: %@\nInital URL: %@\nRedirect URL:%@", NSStringFromClass(self.class), rule, request.URL, resolved);
                return nil;
            }

            NSString *mimeType = @"application/octet-stream"; //TODO: Should we determine from extension or add it as part of the rule?
            NSUInteger expectedContentLength = data.length;
            NSString *textEncodingName = nil; //TODO:
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:expectedContentLength textEncodingName:textEncodingName];
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];

            return cachedResponse;
        }
    }

    //Check the defaultResponseHandler
    if (self.defaultResponseHandler != NULL) {
        id connectionHelper = [BCLNonCachingHTTPConnection class];
        NSCachedURLResponse *cachedResponse = self.defaultResponseHandler(request, connectionHelper);
        if (cachedResponse != nil) {
            return cachedResponse;
        }
    }

    //Fallback to the parentCache
//    return [self.parentCache cachedResponseForRequest:request];
    return nil;
}



#pragma mark - Methods to pass onto parent cache

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
//#pragma message "TODO: How do we prevent parent cache from storing responses from self?"
//    [self.parentCache storeCachedResponse:cachedResponse forRequest:request];
}



//- (void)removeCachedResponseForRequest:(NSURLRequest *)request
//{
//    [self.parentCache removeCachedResponseForRequest:request];
//}
//
//
//
//- (void)removeAllCachedResponses
//{
//    [self.parentCache removeAllCachedResponses];
//}
//
//
//
//- (void)removeCachedResponsesSinceDate:(NSDate *)date
//{
//    id parentCache = self.parentCache;
//    if ([parentCache respondsToSelector:@selector(removeCachedResponsesSinceDate:)]) {
//        [parentCache removeCachedResponsesSinceDate:date];
//    }
//}
//
//
//
//- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forDataTask:(NSURLSessionDataTask *)dataTask
//{
//    id parentCache = self.parentCache;
//    if ([parentCache respondsToSelector:@selector(storeCachedResponse:forDataTask:)]) {
//        [parentCache storeCachedResponse:cachedResponse forDataTask:dataTask];
//    }
//}
//
//
//
//- (void)getCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask completionHandler:(void (^) (NSCachedURLResponse *cachedResponse))completionHandler
//{
//    id parentCache = self.parentCache;
//    if ([parentCache respondsToSelector:@selector(getCachedResponseForDataTask:completionHandler:)]) {
//        [parentCache getCachedResponseForDataTask:dataTask completionHandler:completionHandler];
//    }
//}
//
//
//
//- (void)removeCachedResponseForDataTask:(NSURLSessionDataTask *)dataTask
//{
//    id parentCache = self.parentCache;
//    if ([parentCache respondsToSelector:@selector(removeCachedResponseForDataTask:)]) {
//        [parentCache removeCachedResponseForDataTask:dataTask];
//    }
//}

@end
