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

- (void)testDirect200
{
    //Give
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com/ipad"]];

    //When
    id actualResponse = nil;
    NSError *actualError = nil;
    NSData *actualData = [BCLNonCachingHTTPConnection sendSynchronousRequest:request returningResponse:&actualResponse error:&actualError];

    //Then
    id expectedResponse = nil;
    NSError *expectedError = nil;
    NSData *expectedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&expectedResponse error:&expectedError];

    XCTAssertEqualObjects(actualData, expectedData);
    XCTAssertEqualObjects(actualError, expectedError);
    XCTAssertEqualObjects([actualResponse URL], [expectedResponse URL]);
    XCTAssertEqual([actualResponse statusCode], [expectedResponse statusCode]);
    //We don't compare the response headers because ???
}



//- (void)testDirect200HTTPS
//{
//    //Give
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://twitter.com/"]];
//
//    //When
//    id actualResponse = nil;
//    NSError *actualError = nil;
//    NSData *actualData = [BCLNonCachingHTTPConnection sendSynchronousRequest:request returningResponse:&actualResponse error:&actualError];
//
//    //Then
//    id expectedResponse = nil;
//    NSError *expectedError = nil;
//    NSData *expectedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&expectedResponse error:&expectedError];
//
//    XCTAssertEqualObjects(actualData, expectedData);
//    XCTAssertEqualObjects(actualError, expectedError);
//    XCTAssertEqualObjects([actualResponse URL], [expectedResponse URL]);
//    XCTAssertEqual([actualResponse statusCode], [expectedResponse statusCode]);
//    //We don't compare the response headers because ???
//}



- (void)test30xThen200
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.co.uk/ipad"]];

    //When
    id actualResponse = nil;
    NSError *actualError = nil;
    NSData *actualData = [BCLNonCachingHTTPConnection sendSynchronousRequest:request returningResponse:&actualResponse error:&actualError];

    //Then
    id expectedResponse = nil;
    NSError *expectedError = nil;
    NSData *expectedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&expectedResponse error:&expectedError];

    XCTAssertEqualObjects(actualData, expectedData);
    XCTAssertEqualObjects(actualError, expectedError);
    XCTAssertEqualObjects([actualResponse URL], [expectedResponse URL]);
    XCTAssertEqual([actualResponse statusCode], [expectedResponse statusCode]);
    //We don't compare the response headers because ???
}



- (void)test404
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com/nexus6"]];

    //When
    id actualResponse = nil;
    NSError *actualError = nil;
    NSData *actualData = [BCLNonCachingHTTPConnection sendSynchronousRequest:request returningResponse:&actualResponse error:&actualError];

    //Then
    id expectedResponse = nil;
    NSError *expectedError = nil;
    NSData *expectedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&expectedResponse error:&expectedError];

    XCTAssertEqualObjects(actualData, expectedData);
    XCTAssertEqualObjects(actualError, expectedError);
    XCTAssertEqualObjects([actualResponse URL], [expectedResponse URL]);
    XCTAssertEqual([actualResponse statusCode], [expectedResponse statusCode]);
    //We don't compare the response headers because ???
}



-(void)testInvalidURL
{
    //Given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://appledotcom/nexus6"]];

    //When
    id actualResponse = nil;
    NSError *actualError = nil;
    NSData *actualData = [BCLNonCachingHTTPConnection sendSynchronousRequest:request returningResponse:&actualResponse error:&actualError];

    //Then
    id expectedResponse = nil;
    NSError *expectedError = nil;
    NSData *expectedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&expectedResponse error:&expectedError];

    XCTAssertEqualObjects(actualData, expectedData);
    XCTAssertEqual(actualError != nil, expectedError != nil);
    XCTAssertEqualObjects([actualResponse URL], [expectedResponse URL]);
    XCTAssertEqual([actualResponse statusCode], [expectedResponse statusCode]);
    //We don't compare the response headers because ???
}

@end
