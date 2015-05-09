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



@interface BCLRedirectingURLCache ()
@property(atomic, readonly) NSArray *rewriteRules;
@end




@implementation BCLRedirectingURLCache

#pragma mark - instance life cycle
- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path
{
    return [self initWithParentCache:nil rewriteRulesPath:nil resourceRootPath:nil defaultResponseHandler:NULL];
}



-(instancetype)initWithParentCache:(NSURLCache *)parentCache rewriteRulesPath:(NSString *)rewriteRulesPath resourceRootPath:(NSString *)rawResourceRootPath defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultResponseHandler
{
    self = [super initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];

    if (self == nil) {
        return nil;
    }

    _parentCache = parentCache;
    _rewriteRulesPath = [rewriteRulesPath copy];
    NSString *resourceRootPath = (rawResourceRootPath == nil) ? [[NSBundle mainBundle] bundlePath] : [rawResourceRootPath copy];
    _resourceRootPath = resourceRootPath;
    _defaultResponseHandler = defaultResponseHandler;
    _rewriteRules = [BCLRedirectingURLCacheRedirectionRule rewriteRulesFromFile:rewriteRulesPath];

    return self;
}



#pragma mark - Useful NSURLCache methods
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    //Check the rules
    for (BCLRedirectingURLCacheRedirectionRule *rule in self.rewriteRules) {
        NSURL *resolved = [rule resolvedURLForRequest:request];
        if (resolved != nil) {

            NSData *data = nil;
            if ([resolved.scheme isEqualToString:@"http"]) {
                NSMutableURLRequest *newRequest = [request mutableCopy];
                newRequest.URL = resolved;
                __block NSData *connectionData;
                [BCLNonCachingHTTPConnection sendSynchronousURLRequest:newRequest completionHandler:^(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error) {
                    connectionData = data;
                }];
                data = connectionData;
            }
            else if (resolved.scheme == nil) {
                NSString *path = [self.resourceRootPath stringByAppendingPathComponent:resolved.relativeString];
                data = [NSData dataWithContentsOfFile:path];
            } else {
                //TODO: Unsupported protocol
            }

            NSAssert(data != nil, @"Failed to load data for rule %@", rule);
            //TODO:
            NSString *mimeType = nil;
            NSUInteger expectedContentLength = data.length;
            NSString *textEncodingName = nil;
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:expectedContentLength textEncodingName:textEncodingName];
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];

            return cachedResponse;
        }
    }

    //Check the defaultResponseHandler
    if (self.defaultResponseHandler != NULL) {
        id connectionHelper = [BCLNonCachingHTTPConnection class];
        NSCachedURLResponse *cachedResponse = self.defaultResponseHandler(request, connectionHelper);
        if (cachedResponse) {
            return cachedResponse;
        }
    }

    return [self.parentCache cachedResponseForRequest:request];
}



#pragma message "TODO: Call self.parentCache for other methods"

@end
