//
//  BCLNonCachingHTTPConnection.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLNonCachingHTTPConnection.h"
#import <pthread.h>



@interface BCLNonCachingHTTPConnection ()
@property(atomic, readonly) NSMutableData *responseBodyData;
@end





void *scheduleReadStream(void *replyStream)
{
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFReadStreamScheduleWithRunLoop(replyStream, runloop, kCFRunLoopCommonModes);
    CFRunLoopRun();
    return NULL;
}



void MyReadCallback(CFReadStreamRef stream, CFStreamEventType type, void *userData)
{
    BCLNonCachingHTTPConnection *connection = (__bridge BCLNonCachingHTTPConnection *)userData;
    switch (type) {
        case kCFStreamEventNone:
            break;

        case kCFStreamEventOpenCompleted:
            break;

        case kCFStreamEventHasBytesAvailable: {
#pragma message "TODO: What's a sensible value for the buffer size?"
#define READ_SIZE 256
            UInt8 buffer[READ_SIZE];
            //   leave 1 byte for a trailing null.
            CFIndex bytesRead = CFReadStreamRead(stream, buffer, READ_SIZE-1);
            [connection.responseBodyData appendBytes:buffer length:bytesRead];
            break;
        }

        case kCFStreamEventCanAcceptBytes:
            break;

        case kCFStreamEventErrorOccurred:
            CFRunLoopStop(CFRunLoopGetCurrent());
            break;

        case kCFStreamEventEndEncountered:
            CFRunLoopStop(CFRunLoopGetCurrent());
            break;

    }
    
}



@implementation BCLNonCachingHTTPConnection

+(void)sendSynchronousURLRequest:(NSURLRequest *)request completionHandler:(void(^)(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    BCLNonCachingHTTPConnection *connection = [[BCLNonCachingHTTPConnection alloc] initWithURLRequest:request];
    [connection sendSynchronously:completionHandler];
}



-(instancetype)initWithURLRequest:(NSURLRequest *)request
{
    NSParameterAssert(request);

    self = [super init];
    if (self == nil) {
        return nil;
    }

    _URLRequest = [request copy];

    _responseBodyData = [NSMutableData new];

    return self;
}



-(void)sendSynchronously:(void(^)(BOOL didSucceed, NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSParameterAssert(completionHandler);

    //Create request
    CFStringRef requestMethod = (__bridge CFStringRef)self.URLRequest.HTTPMethod;
    CFURLRef url = (__bridge CFURLRef)self.URLRequest.URL;
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, url, kCFHTTPVersion1_1);

    //    //Headers
    //    CFStringRef headerFieldName = CFSTR("X-My-Favorite-Field");
    //    CFStringRef headerFieldValue = CFSTR("Dreams");
    //    CFHTTPMessageSetHeaderFieldValue(myRequest, headerFieldName, headerFieldValue);

    //    //Body
    //    CFStringRef bodyString = CFSTR(""); // Usually used for POST data
    //    CFDataRef bodyData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, bodyString, kCFStringEncodingUTF8, 0);
    //    CFDataRef bodyDataExt = CFStringCreateExternalRepresentation(kCFAllocatorDefault, bodyData, kCFStringEncodingUTF8, 0);
    //    CFHTTPMessageSetBody(myRequest, bodyDataExt);

    //Create a stream with the request and enqueue it
    CFReadStreamRef replyStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    CFReadStreamSetProperty(replyStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    CFReadStreamOpen(replyStream);

    CFStreamClientContext context = {.info = (__bridge void *)self};
    BOOL didEnqueue = CFReadStreamSetClient(replyStream, kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered, MyReadCallback, &context);
    if (didEnqueue) {
        /* this variable is our reference to the second thread */
        pthread_t inc_x_thread;

        /* create a second thread which executes inc_x(&x) */
        if(pthread_create(&inc_x_thread, NULL, scheduleReadStream, replyStream) != 0) {
            return;
        }

        /* wait for the second thread to finish */
        if(pthread_join(inc_x_thread, NULL) != 0) {
            return;
        }
    }

    CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(replyStream, kCFStreamPropertyHTTPResponseHeader);
    CFDictionaryRef headers = CFHTTPMessageCopyAllHeaderFields(response);
    CFStringRef statusLine = CFHTTPMessageCopyResponseStatusLine(response);
    CFIndex  statusCode = CFHTTPMessageGetResponseStatusCode(response);
    NSString *version = ({
        NSRange whitespaceRange = [(__bridge NSString *)statusLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [(__bridge NSString *)statusLine substringToIndex:whitespaceRange.location];
    });
    NSURL *responseURL = self.URLRequest.URL; //TODO: We should get the actual URL which will be different due to redirects.
    NSURLResponse *URLResponse = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:statusCode HTTPVersion:version headerFields:(__bridge NSDictionary *)headers];
    NSError *error = nil; //TODO:
    BOOL didSucceed = YES; //TODO:

    //Tidy up
    CFRelease(replyStream);
    CFRelease(request);
    CFRelease(response);
    CFRelease(headers);
    CFRelease(statusLine);

    //Done!
    completionHandler(didSucceed, self.responseBodyData, URLResponse, error);
}

@end
