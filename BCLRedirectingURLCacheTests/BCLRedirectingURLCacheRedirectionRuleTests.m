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

#pragma mark - redirect rules file parsing
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
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule redirectRulesFromString:rules baseURL:nil];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:@"GET" URLRegex:@".*online-categories.*"  URLReplacementPattern:@"online-categories.json" baseURL:nil],
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:@"GET" URLRegex:@"http://example\\.com"  URLReplacementPattern:@"lines.json" baseURL:nil],
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
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule redirectRulesFromString:rules baseURL:nil];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:@"GET" URLRegex:@".*online-categories.*"  URLReplacementPattern:@"online-categories.json" baseURL:nil],
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:@"GET" URLRegex:@"http://example\\.com"  URLReplacementPattern:@"lines.json" baseURL:nil]
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
    XCTAssertThrows([BCLRedirectingURLCacheRedirectionRule redirectRulesFromString:rules baseURL:nil]);
}



-(void)testInvalidLineDueToMissingColumns
{
    //Given
    NSString *rules = @""
    "GET \t lines.json\n"
    ;

    //When & Then
    XCTAssertThrows([BCLRedirectingURLCacheRedirectionRule redirectRulesFromString:rules baseURL:nil]);
}



#pragma mark - Init tests

-(void)testInvalidMethodRegex
{
    //Given
    NSString *methodRegex = @"(GET)|(HEAD";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"http://apple.com$1";
    NSURL *baseURL = nil;

    //When & Then
    XCTAssertThrows([[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL]);
}



-(void)testInvalidURLRegex
{
    //Given
    NSString *methodRegex = @"(GET)|(HEAD)";
    NSString *urlRegex = @"http://fruitshop\\.com(.*";
    NSString *replacementPattern = @"http://apple.com$1";
    NSURL *baseURL = nil;

    //When & Then
    XCTAssertThrows([[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL]);
}



-(void)testNonAbsoluteBaseURL
{
    //Given
    NSString *methodRegex = @"(GET)|(HEAD)";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"$1";
    NSURL *baseURL = [NSURL URLWithString:@"apple.com"];

    //When & Then
    XCTAssertThrows([[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL]);
}



#pragma mark - Functionality tests

-(void)testResolveWithNonMatchingHTTPMethodRegex
{
    //Given
    NSString *methodRegex = @"HEAD";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"$1";
    NSURL *baseURL = [NSURL URLWithString:@"http://apple.com"];
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com"]];

    //When
    NSURL *actualResult = [rule resolvedURLForRequest:request];

    //Then
    id expectedResult = nil;
    XCTAssertEqualObjects(actualResult, expectedResult);
}



-(void)testResolveWithPartiallyMatchingHTTPMethodRegex
{
    //Given
    NSString *methodRegex = @"GE";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"$1";
    NSURL *baseURL = [NSURL URLWithString:@"http://apple.com"];
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com"]];

    //When
    NSURL *actualResult = [rule resolvedURLForRequest:request];

    //Then
    id expectedResult = nil;
    XCTAssertEqualObjects(actualResult, expectedResult);
}



-(void)testResolveWithPartiallyMatchingURLRegex
{
    //Given
    NSString *methodRegex = @"GET";
    NSString *urlRegex = @"ttp://fruitshop\\.co";
    NSString *replacementPattern = @"$1";
    NSURL *baseURL = [NSURL URLWithString:@"http://apple.com"];
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com/arf/boom"]];

    //When
    NSURL *actualResult = [rule resolvedURLForRequest:request];

    //Then
    id expectedResult = nil;
    XCTAssertEqualObjects(actualResult, expectedResult);
}



-(void)testResolveWithAbsolutePattern
{
    //Given
    NSString *methodRegex = @"GET";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"http://apple.com$1";
    NSURL *baseURL = nil;
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com/arf"]];

    //When
    NSURL *actualResult = [rule resolvedURLForRequest:request];

    //Then
    id expectedResult = [NSURL URLWithString:@"http://apple.com/arf"];
    XCTAssertEqualObjects(actualResult, expectedResult);
}



-(void)testResolveWithRelativePatternAndNilBaseURL
{
    //Given
    NSString *methodRegex = @"GET";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"apple.com$1";
    NSURL *baseURL = nil;
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com/arf"]];

    //When & Then
    XCTAssertThrows([rule resolvedURLForRequest:request]);
}



-(void)testResolveWithRelativePatternAndNonNilBaseURL
{
    //Given
    NSString *methodRegex = @"GET";
    NSString *urlRegex = @"http://fruitshop\\.com(.*)";
    NSString *replacementPattern = @"$1";
    NSURL *baseURL = [NSURL URLWithString:@"http://apple.com"];
    BCLRedirectingURLCacheRedirectionRule *rule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:methodRegex URLRegex:urlRegex URLReplacementPattern:replacementPattern baseURL:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fruitshop.com/arf"]];

    //When
    NSURL *actualResult = [rule resolvedURLForRequest:request];

    //Then
    id expectedResult = [NSURL URLWithString:@"http://apple.com/arf"];
    XCTAssertEqualObjects(actualResult, expectedResult);
}

@end
