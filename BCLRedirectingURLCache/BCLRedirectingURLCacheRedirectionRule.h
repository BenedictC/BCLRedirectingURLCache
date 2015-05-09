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

+(NSArray *)rewriteRulesFromFile:(NSString *)path;
+(NSArray *)rewriteRulesFromString:(NSString *)string;

-(instancetype)initWithMethod:(NSString *)method pathMatchingRegex:(NSString *)regex replacementPattern:(NSString *)replacementPattern;

@property(readonly) NSString *method;
@property(readonly) NSString *pathMatchingRegex;
@property(readonly) NSString *replacementPattern;

-(NSURL *)resolvedURLForRequest:(NSURLRequest *)request;

@end
