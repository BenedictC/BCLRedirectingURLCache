//
//  BCLRedirectingURLCacheTests.m
//  BCLRedirectingURLCacheTests
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLRedirectingURLCache.h"
#import <XCTest/XCTest.h>



@interface BCLRedirectingURLCacheTests : XCTestCase

@end



@implementation BCLRedirectingURLCacheTests

-(void)testRedirectToHTTPSResource
{
    //Given
    BCLRedirectingURLCache *cache = [BCLRedirectingURLCache cacheWithRedirectRulesFileNamed:@"arf" defaultResponseHandler:NULL];
    cache.logHandler = BCLRedirectingURLCacheDefaultLogHandler;

    //When

    //Then
}

#pragma message "TODO: Test factory methods"
#pragma message "TODO: Test that path of  redirects file is being used as resource root when resource root is nil"

#pragma message "TODO: Test different protocols load correctly"
#pragma message "TODO: Test behaviour when unable to load subsitute resource"
//#pragma message "TODO: Test parent cache functionality"


-(void)testResolveWithMissingReplacementResource
{
    //Given

    //When
//    id actualResult = [NSObject new];

    //Then
//    id expectedResult = [NSObject new];
//    XCTAssertEqualObjects(actualResult, expectedResult);
}

@end
