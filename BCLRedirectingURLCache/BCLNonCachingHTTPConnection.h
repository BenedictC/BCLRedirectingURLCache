//
//  BCLNonCachingHTTPConnection.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 09/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCLNonCachingHTTPConnection : NSObject

+(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;

-(instancetype)initWithURLRequest:(NSURLRequest *)request NS_DESIGNATED_INITIALIZER;
@property(atomic, readonly) NSURLRequest *URLRequest;

-(NSData *)sendSynchronouslyAndReturnResponse:(NSURLResponse **)response error:(NSError **)error;

@end
