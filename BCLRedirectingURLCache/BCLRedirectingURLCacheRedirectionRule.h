//
//  BCLRedirectingURLCacheRedirectionRule.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



extern NSString * const BCLRedirectingURLCacheRedirectionRuleMethodWildcard;



@interface BCLRedirectingURLCacheRedirectionRule : NSObject

+(NSArray *)rewriteRulesFromContentsOfFile:(NSString *)path baseURL:(NSURL *)baseURL;
+(NSArray *)rewriteRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL;

-(instancetype)initWithMethod:(NSString *)method pathMatchingRegex:(NSString *)regex replacementPattern:(NSString *)replacementPattern baseURL:(NSURL *)baseURL;

@property(readonly) NSString *method;
@property(readonly) NSString *pathMatchingRegex;
@property(readonly) NSString *replacementPattern;
@property(readonly) NSURL *baseURL;

-(NSURL *)resolvedURLForRequest:(NSURLRequest *)request;

@end
