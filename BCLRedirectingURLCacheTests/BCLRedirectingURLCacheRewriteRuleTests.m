//
//  BCLRedirectingURLCacheRedirectionRuleTests.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BCLRedirectingURLCacheRedirectionRule.h"



@interface BCLRedirectingURLCacheRedirectionRuleTests : XCTestCase

@end



@implementation BCLRedirectingURLCacheRedirectionRuleTests

//Parsing tests
-(void)testWhitespaceParsing
{
    //Given
    NSString *rules = @""
    "         # This is a comment\n" //leading white space on a comment
    "\t    GET \t .*online-categories.*  \t    online-categories.json  \t          \n" //Leading whitespace and spacing whitespace
    "\n       \t \n" //Nonsese whitespace
    "GET\thttp://example\\.com\tlines.json" //just tabs and non-new line terminated
    ;

    //When
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:@"GET" pathMatchingRegex:@".*online-categories.*" replacementPattern:@"online-categories.json" baseURL:nil],
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:@"GET" pathMatchingRegex:@"http://example\\.com" replacementPattern:@"lines.json" baseURL:nil]
                               ];
    XCTAssertEqualObjects(actualRules, expectedRules);
}



-(void)testCommentParsing
{
    //Given
    NSString *rules = @""
    "   # This is a comment\n" //padded comment
    "GET .*online-categories.* online-categories.json # More comments!\n" //trailing comment
    "# This is another comment\n" //non-padded comment
    "GET http://example\\.com lines.json\n"
    ;

    //When
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:@"GET" pathMatchingRegex:@".*online-categories.*" replacementPattern:@"online-categories.json" baseURL:nil],
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:@"GET" pathMatchingRegex:@"http://example\\.com" replacementPattern:@"lines.json" baseURL:nil]
                               ];
    XCTAssertEqualObjects(actualRules, expectedRules);
}



-(void)testInvalidLineDueToAdditionalColumns
{
    //Given
    NSString *rules = @""
    "* http://example\\.com    lines.json\\sarf  wgrehtr"
    ;

    //When & Then
    XCTAssertThrows([BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil]);
}



-(void)testInvalidLineDueToMissingColumns
{
    //Given
    NSString *rules = @""
    "GET \t lines.json\n"
    ;

    //When & Then
    XCTAssertThrows([BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil]);
}



-(void)testInvalidMethod
{
    //Given
    NSString *rules = @""
    "METH0D http://example\\.com    lines.json"
    ;

    //When & Then
    XCTAssertThrows([BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil]);
}



-(void)testWildcardMethodParsing
{
    //Given
    NSString *rules = @""
    "* .*online-categories.*  online-categories.json"
    ;

    //When
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:rules baseURL:nil];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:BCLRedirectingURLCacheRedirectionRuleMethodWildcard pathMatchingRegex:@".*online-categories.*" replacementPattern:@"online-categories.json" baseURL:nil],
                               ];
    XCTAssertEqualObjects(actualRules, expectedRules);
}



//Functionality tests
//TODO: absolute path resolution
//TODO: relative path resolution with baseURL
//TODO: relative path resolution without baseURL
//TODO: failing path resolution

@end
