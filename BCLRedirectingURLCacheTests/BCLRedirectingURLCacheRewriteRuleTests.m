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



//Functionality tests
#pragma message "TODO: failing method resolution"
#pragma message "TODO: absolute path resolution"
#pragma message "TODO: relative path resolution with baseURL"
#pragma message "TODO: relative path resolution without baseURL"
#pragma message "TODO: failing path resolution"



@end
