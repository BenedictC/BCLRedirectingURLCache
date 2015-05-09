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

-(void)testRewriteRuleParsing
{
    //Given
    NSString *string = @""
    "         # This is a comment\n"
    "* \n\n\t .*online-categories.*  \t    online-categories.json  \t          \n"
    "GET http://example\\.com    lines.json     \n"
    "\n       \t \n"
    ;

    //When
    NSArray *actualRules = [BCLRedirectingURLCacheRedirectionRule rewriteRulesFromString:string];

    //Then
    NSArray *expectedRules = @[
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:BCLRedirectingURLCacheRedirectionRuleMethodWildcard pathMatchingRegex:@".*online-categories.*" replacementPattern:@"online-categories.json"],
                               [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:@"GET" pathMatchingRegex:@"http://example\\.com" replacementPattern:@"lines.json"]
                               ];
    XCTAssertEqualObjects(actualRules, expectedRules);
}


@end
