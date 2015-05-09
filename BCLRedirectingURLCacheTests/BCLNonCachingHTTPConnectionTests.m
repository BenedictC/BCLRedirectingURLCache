//
//  BCLNoncachingHTTPRequestTests.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BCLNonCachingHTTPConnection.h"



@interface BCLNonCachingHTTPConnectionTests : XCTestCase

@end




@implementation BCLNonCachingHTTPConnectionTests

- (void)testConnection
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com"]];
    BCLNonCachingHTTPConnection *connection = [[BCLNonCachingHTTPConnection alloc] initWithURLRequest:request];
    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    [connection sendSynchronously:^(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@\n%@", response, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:20 handler:NULL];
}

@end



