//
//  BCLRedirectingURLCacheTests.m
//  BCLRedirectingURLCacheTests
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLRedirectingURLCache.h"
#import "BCLRedirectingURLCacheRedirectionRule.h"
#import "BCLNonCachingHTTPConnection.h"
#import <XCTest/XCTest.h>



#pragma mark - global variables 
//(we can't used properties on the test case because the tests do strange things behind the scenes.)
static NSUInteger gDefaultHandlerInvocationCount;
static NSData *gResponseData;




@interface BCLRedirectingURLCacheTests : XCTestCase
@end



@implementation BCLRedirectingURLCacheTests

//We configure one instance to be used by all tests because setSharedURLCache: should only be called before any network requests are made.
- (id)initWithInvocation:(NSInvocation *)invocation
{
    self = [super initWithInvocation:invocation];
    NSString *rulesText = @""
    ".+ http://example\\.com/\\?testRedirectToFileResource              LICENSE"                               "\n"
    ".+ http://example\\.com/\\?testRedirectToHTTPResource              http://apple.com"                      "\n"
    ".+ http://example\\.com/\\?testRedirectToHTTPSResource             https://en.wikipedia.org/wiki/HTTPS"   "\n"
    ".+ http://example\\.com/\\?testCacheWithMissingReplacementResource file:///thisfiledoesnotexist"          "\n"
    "";
    NSURL *baseURL = [[NSBundle bundleForClass:self.class] resourceURL];
    NSArray *rules = [BCLRedirectingURLCacheRedirectionRule redirectRulesFromString:rulesText baseURL:baseURL];

//    __weak typeof(self) weakSelf = self;
    BCLRedirectingURLCache *cache = [[BCLRedirectingURLCache alloc] initWithRedirectRules:rules defaultResponseHandler:^NSCachedURLResponse *(NSURLRequest *request, id<BCLNonCachingHTTPConnectionService> service) {
        gDefaultHandlerInvocationCount++;

        NSData *data = gResponseData;
        if (data == nil) {
            return nil;
        }

        NSString *mimeType = @"application/octet-stream";
        NSUInteger expectedContentLength = data.length;
        NSString *textEncodingName = nil;
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:expectedContentLength textEncodingName:textEncodingName];
        NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];

        return cachedResponse;
    }];
    [NSURLCache setSharedURLCache:cache];

    return self;
}



-(void)testRedirectToFileResource
{
    //Given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/?testRedirectToFileResource"]];

    //When
    NSData *actualData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

    //Then
    NSData *expectedData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"LICENSE" withExtension:nil]];
    XCTAssertEqualObjects(actualData, expectedData);
}



-(void)testRedirectToHTTPResource
{
    //Given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/?testRedirectToHTTPResource"]];

    //When
    NSData *actualData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

    //Then
    NSData *expectedData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://apple.com"]];
    XCTAssertEqualObjects(actualData, expectedData);
}



-(void)testRedirectToHTTPSResource
{
    //Given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/?testRedirectToHTTPSResource"]];

    //When
    NSData *actualData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

    //Then
    NSData *expectedData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://en.wikipedia.org/wiki/HTTPS"]];
    XCTAssertEqualObjects(actualData, expectedData);
}



-(void)testCacheWithMissingReplacementResource
{
    //Given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/?testCacheWithMissingReplacementResource"]];
    NSUInteger expectedCount = gDefaultHandlerInvocationCount;
    //When
    NSData *actualData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

    //Then
    NSData *expectedData = [NSData dataWithContentsOfURL:request.URL];
    XCTAssertEqualObjects(actualData, expectedData);

    NSUInteger actualCount = gDefaultHandlerInvocationCount;
    XCTAssertEqual(actualCount, expectedCount, @"defaultHandlerInvocationCount was incremented during test which means block was eroneously invoked.");
}



-(void)testDefaultHandlerIsCalledWhenNoRulesMatch
{
    //Given
    gResponseData = [@"testDefaultHandlerIsCalledWhenNoRulesMatch" dataUsingEncoding:NSUTF8StringEncoding];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/?testDefaultHandlerIsCalledWhenNoRulesMatch"]];
    NSUInteger expectedCount = 1 + gDefaultHandlerInvocationCount;

    //When
    NSData *actualData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];

    //Then
    NSData *expectedData = gResponseData;
    XCTAssertEqualObjects(expectedData, actualData);

    NSUInteger actualCount = gDefaultHandlerInvocationCount;
    XCTAssertEqual(actualCount, expectedCount, @"defaultHandlerInvocationCount was not incremented during test which means block was not invoked.");
}

@end
