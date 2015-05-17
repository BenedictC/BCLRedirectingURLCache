//
//  BCLRedirectingURLCache.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

/*
 
 # BCLRedirectingURLCache
 
 ## Overview
 
 BCLRedirectingURLCache is a NSURLCache subclass which allows URL requests made by Foundation framework classes (NSURLSession & NSURLConnection) to be redirected to either local files or another HTTP(s) resource. Possible uses for BCLRedirectingURLCache are:
 - Stubbing of HTTP resources for testing purposes
 - Stubbing of unstable/unavailable HTTP resources during development
 - Serving static content to web views
 
 BCLRedirectingURLCache provides 2 mechanisms for serving alternative content; redirect rules and a default response handler. For most cases redirect rules are sufficient and the simplest method to implement. Redirect rules take precedence over the default response handler.
 
 

 ## Redirect Rules
 
 Redirect rules are similar to Apache rewrite rules. A redirect rule consists of 4 parts; a string to match the HTTP method against, a regular expression to evaluate against the request URL, a URL replacement pattern to redirect to and base URL to resolve the output of the URL replacement pattern against. The simplest way to construct redirect rules is with a redirect file. A redirect file consists of a series of redirect rules expressed as 3 columns; method regex, URL regex and replacement pattern. The base URL is not stated within the redirect file, it is provided as parameter to the cache's init method. An example redirect file:

 ```
# This line is a comment. Comments are lines that start with a hash. They behave like '//' C style comments.

# The next line is a redirect rule that matches GET requests to a specific URL and redirects them to a static file:
GET     http://api.webguysstillworkingonthis\.com/lots-of-data.json.*       sample\sJSON/static-lots-of-data.json              # This is a trailing comment.

# Things to note:
# - The line is made of exactly 3 columns; the method regex, the URL regex and the URL replacement pattern.
# - Whitespace is not allows in any values. Whitespace can be inserted into the URL replacement pattern using escape sequences; \s = space, \t = tab, \n = newline.
# - The replacement pattern will create a relative URL, not a absolute URL. This means that at runtime time it will be resolved against the base URL.



# A redirect that matches all requests to fruitshop.com and redirects them to apple.com:
.*        http(s?)//:fruitshop\.com(.*)       http$1//:apple.com$2

# Things to note:
# - Capture groups in the URL regex are consumed by the URL replacement pattern.
# - The replacement pattern will create an absolute URL so, unlike the previous rule, will not be resolved against the base URL.

 ```


 
 ## Default Response Handler

 The default response handler allows for dynamic content to be created at runtime. The default response handler is only executed if a request does not match any of the redirect rules. If a request matches a redirect rule but the cache fails to create a response due to missing data then the default response handler will not be executed.
 
 The default response handler is executed on a background thread managed by the NSURL loading mechanism. Making a network request that involves the NSURL loading mechanism from within a default response handler will result in a deadlock. To avoid such deadlocks the BCLNonCachingHTTPConnectionService object provided to the default response handler should be used to make HTTP and HTTPS requests.

 */


#import <Foundation/Foundation.h>



static void (^ const BCLRedirectingURLCacheDefaultLogHandler)(NSString *message) = ^(NSString *message){
    NSLog(@"%@", message);
};



@protocol BCLNonCachingHTTPConnectionService <NSObject>
/**
 Performs a synchronous load of the specified URL request without checking the URL cache.

 @param request  The URL request to load.
 @param response Out parameter for the URL response returned by the server. NULL is permitted.
 @param error    Out parameter used if an error occurs while processing the request. NULL is permitted.

 @return The downloaded data for the URL request. Returns nil if a connection could not be created or if the download fails.
 */

-(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

@end



@interface BCLRedirectingURLCache : NSURLCache

/**
 Returns a new URL cache. Redirect rules are loaded from fileName in the main bundle and the resource root path is also

 @param fileName       The name of the file in the main bundle that contains the redirect rules. `nil` is permitted.
 @param defaultHandler A block for handling responses that do not match any of the redirect rules. `NULL` is permitted.

 @return A new URL cache.
 */
+(instancetype)cacheWithRedirectRulesFileNamed:(NSString *)fileName defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper))defaultHandler;
/**
 Returns a new URL cache. Redirect rules are loaded from the file at redirectRulesPath. If baseURL is `nil` then it is assumed to be the parent folder of the redirectRulesPath.

 @param redirectRulesPath The path of the file that contains the redirect rules. `nil` is permitted.
 @param baseURL           An absolute URL that relative URLs are resolved against. `nil` is permitted.
 @param defaultHandler    A block for handling responses that do not match any of the redirect rules. `NULL` is permitted.

 @return A new URL cache.
 */
+(instancetype)cacheWithRedirectRulesPath:(NSString *)redirectRulesPath baseURL:(NSURL *)baseURL defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultHandler;

/**
 Returns a new URL cache object initialized with the given attributes.

 @param redirectRules     An array of BCLRedirectingURLCacheRedirectionRule instances. `nil` is permitted.
 @param defaultHandler    A block for handling responses that do not match any of the redirect rules. `NULL` is permitted.

 @return A new URL cache.
 */
-(instancetype)initWithRedirectRules:(NSArray *)redirectRules defaultResponseHandler:(NSCachedURLResponse *(^)(NSURLRequest *, id<BCLNonCachingHTTPConnectionService>))defaultResponseHandler NS_DESIGNATED_INITIALIZER;

/**
 An array of BCLRedirectingURLCacheRedirectionRule instances that requests are evaluated against.
 */
@property(atomic, readonly) NSArray *redirectRules;
/**
 A block for handling responses that do not match any of the redirect rules.
 */
@property(atomic, readonly) NSCachedURLResponse *(^defaultResponseHandler)(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> connectionHelper);
/**
 A block that is invoked when the instance needs to log an error. Defaults to BCLRedirectingURLCacheDefaultLogHandler.
 */
@property(atomic, copy) void (^logHandler)(NSString *message);

@end
