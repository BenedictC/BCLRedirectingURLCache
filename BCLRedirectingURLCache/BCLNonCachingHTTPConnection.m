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





void *readStreamMain(void *replyStream)
{
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFReadStreamScheduleWithRunLoop(replyStream, runloop, kCFRunLoopCommonModes);
    CFRunLoopRun();
    return NULL;
}



void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType type, void *connectionRef)
{
    BCLNonCachingHTTPConnection *connection = (__bridge BCLNonCachingHTTPConnection *)connectionRef;
    switch (type) {
        case kCFStreamEventNone:
            break;

        case kCFStreamEventOpenCompleted:
            break;

        case kCFStreamEventHasBytesAvailable: {
            const int bufferSize = 1024;
            UInt8 buffer[bufferSize];
            //   leave 1 byte for a trailing null.
            CFIndex bytesRead = CFReadStreamRead(stream, buffer, bufferSize-1);
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

+(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    BCLNonCachingHTTPConnection *connection = [[BCLNonCachingHTTPConnection alloc] initWithURLRequest:request];
    return [connection sendSynchronouslyAndReturnResponse:response error:error];
}



-(instancetype)initWithURLRequest:(NSURLRequest *)request
{
    NSParameterAssert(request);

    self = [super init];
    if (self == nil) {
        return nil;
    }

    //[NSURLRequest copy] is strange. NSURLRequest does not copy headers and body when they are set which means they can be mutated arbitarily.
    NSMutableURLRequest *copy = [request mutableCopy];
    copy.HTTPBody = [request.HTTPBody copy];
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [copy setValue:[obj copy] forHTTPHeaderField:key];
    }];
    //Prevent the response from being compressed
    //TODO: This is not the best solution. Read the HTTP spec and then do something better.
    [copy setValue:nil forHTTPHeaderField:@"Accept-Encoding"];
    _URLRequest = copy;

    _responseBodyData = [NSMutableData new];

    return self;
}



-(CFHTTPMessageRef)createMessage CF_RETURNS_RETAINED
{
    NSURLRequest *originalRequest = self.URLRequest;
    CFStringRef requestMethod = (__bridge CFStringRef)originalRequest.HTTPMethod;
    CFURLRef url = (__bridge CFURLRef)originalRequest.URL;
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, url, kCFHTTPVersion1_1);

    //Headers
    [originalRequest.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *headerValue, BOOL *stop) {
        CFHTTPMessageSetHeaderFieldValue(request, (__bridge CFStringRef)headerName, (__bridge CFStringRef)headerValue);
    }];

    //Body
#pragma message "TODO: We also need to check .HTTPBodyStream for data."
    if (originalRequest.HTTPBody != nil) {
        CFHTTPMessageSetBody(request, (__bridge CFDataRef)originalRequest.HTTPBody);
    }

    return request;
}



-(NSError *)enqueueOpenedStreamAndWaitForCompletion:(CFReadStreamRef)stream
{
    //Enqueue the stream and wait for it to complete
    CFStreamClientContext context = {.info = (__bridge void *)self};
    BOOL didEnqueue = CFReadStreamSetClient(stream, kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered, readStreamEventHandler, &context);
    if (!didEnqueue) {
        NSAssert(NO, @"Failed to add client for network stream.");
        return nil;
    }

    pthread_t streamThread;
    if(pthread_create(&streamThread, NULL, readStreamMain, stream) != 0) {
        NSAssert(NO, @"Unable to create thread for network request.");
        return nil;
    }

    if(pthread_join(streamThread, NULL) != 0) {
        NSAssert(NO, @"Unable to join thread for network request.");
        return nil;
    }

    //Get error from the stream
    return (__bridge_transfer NSError *) CFReadStreamCopyError(stream);
}



-(NSData *)sendSynchronouslyAndReturnResponse:(NSURLResponse **)outResponse error:(NSError **)outError
{
    //Create request and a stream for it
    CFHTTPMessageRef request = [self createMessage];
    CFReadStreamRef httpStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request); //We could cast this to an NSInputStream but that would get messy when accessing properties.
    CFReadStreamSetProperty(httpStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    CFReadStreamOpen(httpStream);

    //Get the data from the stream
    NSError *error = [self enqueueOpenedStreamAndWaitForCompletion:httpStream];

    //Create NSURLResponse
    if (error == nil && outResponse != NULL) {
        NSURL *finalURL = (__bridge_transfer NSURL *)CFReadStreamCopyProperty(httpStream, kCFStreamPropertyHTTPFinalURL);

        CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(httpStream, kCFStreamPropertyHTTPResponseHeader);
        CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(response);
        NSDictionary *headers = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(response);
        NSString *statusLine = (__bridge_transfer NSString *)CFHTTPMessageCopyResponseStatusLine(response);
        NSString *version = ({
            NSRange whitespaceRange = [statusLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [statusLine substringToIndex:whitespaceRange.location];
        });
        *outResponse = [[NSHTTPURLResponse alloc] initWithURL:finalURL statusCode:statusCode HTTPVersion:version headerFields:headers];

        //Tidy up
        if (response) CFRelease(response);
    }

    //Tidy up
    if (request)    CFRelease(request);
    if (httpStream) CFRelease(httpStream);

    //Done!
    if (outError != nil) {
        *outError = error;
    }
    BOOL didSucceed = (error == nil);
    return (didSucceed) ? self.responseBodyData : nil;
}

@end
