//
//  BCLRedirectingURLCacheRedirectionRule.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCLRedirectingURLCacheRedirectionRule : NSObject

+(NSArray *)redirectRulesFromContentsOfFile:(NSString *)path baseURL:(NSURL *)baseURL;
+(NSArray *)redirectRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL;

-(instancetype)initWithMethodRegex:(NSString *)methodRegex URLRegex:(NSString *)URLRegex URLReplacementPattern:(NSString *)replacementPattern baseURL:(NSURL *)baseURL;

@property(readonly) NSString *methodRegex;
@property(readonly) NSString *URLRegex;
@property(readonly) NSString *URLReplacementPattern;
@property(readonly) NSURL *baseURL;

-(NSURL *)resolvedURLForRequest:(NSURLRequest *)request;

@end
