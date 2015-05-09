//
//  BCLRedirectingURLCacheRedirectionRule.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLRedirectingURLCacheRedirectionRule.h"



NSString * const BCLRedirectingURLCacheRedirectionRuleMethodWildcard = @"*";



@interface BCLRedirectingURLCacheRedirectionRule ()
@property(readonly) NSRegularExpression *pathMatcher;
@end




@implementation BCLRedirectingURLCacheRedirectionRule

#pragma mark - parsing
+(NSArray *)rewriteRulesFromFile:(NSString *)path
{
    if (path == nil) {
        return @[];
    }

    NSString *rewriteRulesContent = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:NULL];
    return [self rewriteRulesFromString:rewriteRulesContent path:path];
}



+(NSArray *)rewriteRulesFromString:(NSString *)string
{
    return [self rewriteRulesFromString:string path:nil];
}



+(NSArray *)rewriteRulesFromString:(NSString *)string path:(NSString *)rewriteRulesPath
{
    NSParameterAssert(string);
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;

    NSMutableArray *rewriteRules = [NSMutableArray new];
    while ([self scanComments:scanner]) {
        NSString *method = nil;
        BOOL didScanMethod = [self scanRequestMethodFromScanner:scanner intoMethod:&method];
        NSAssert(didScanMethod, @"Failed to scan method for RewriteRule at character %@ of %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>");

        NSString *regex = nil;
        BOOL didScanRegex = [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&regex];
        NSAssert(didScanRegex, @"Failed to scan regex for RewriteRule at character %@ of %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>");

        NSString *rawReplacementPattern = nil;
        BOOL didScanReplacementPattern = [scanner scanUpToString:@"\n" intoString:&rawReplacementPattern];
        NSAssert(didScanReplacementPattern, @"Failed to resource path for RewriteRule at character %@ of %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>");
        [scanner scanString:@"\n" intoString:NULL];

        NSString *replacementPattern = [rawReplacementPattern stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BCLRedirectingURLCacheRedirectionRule *rewriteRule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:method pathMatchingRegex:regex replacementPattern:replacementPattern];
        [rewriteRules addObject:rewriteRule];
    }

    return [rewriteRules copy];
}



+(BOOL)scanComments:(NSScanner *)scanner
{
    //Gobble up leading whitespace
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];

    while ([scanner scanString:@"#" intoString:NULL]) {
        [scanner scanUpToString:@"\n" intoString:NULL];
    }

    //Gobble up trailing whitespace
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];

    return ![scanner isAtEnd];
}



+(BOOL)scanRequestMethodFromScanner:(NSScanner *)scanner intoMethod:(NSString **)method
{
    NSParameterAssert(method);

    if (   [scanner scanString:BCLRedirectingURLCacheRedirectionRuleMethodWildcard intoString:method]
        || [scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:method]) {
        //If there's no whitespace then the scan failed
        BOOL didScanWhitespace = [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        return didScanWhitespace;
    }

    return NO;
}



#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithMethod:nil pathMatchingRegex:nil replacementPattern:nil];
}



-(instancetype)initWithMethod:(NSString *)method pathMatchingRegex:(NSString *)pathMatchingRegex replacementPattern:(NSString *)replacementPattern
{
    NSParameterAssert(method);
    NSParameterAssert(pathMatchingRegex);
    NSParameterAssert(replacementPattern);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _method = method;
    _pathMatchingRegex = [pathMatchingRegex copy];
    _replacementPattern = [replacementPattern copy];
    NSError *error;
    _pathMatcher = [[NSRegularExpression alloc] initWithPattern:pathMatchingRegex options:0 error:&error];
    NSAssert(_pathMatcher != nil, @"\\%@\\ in not a valid regular expression: %@", pathMatchingRegex, error);

    return self;
}



#pragma mark - evaluation
-(NSURL *)resolvedURLForRequest:(NSURLRequest *)request
{
    NSParameterAssert(request);

    BOOL didMatchMethod = [self.method isEqualToString:BCLRedirectingURLCacheRedirectionRuleMethodWildcard] || [self.method isEqualToString:request.HTTPMethod];
    if (!didMatchMethod) {
        return nil;
    }

    NSString *input = request.URL.absoluteString;
    NSMatchingOptions options = 0;
    NSRange range = NSMakeRange(0, input.length);
    NSRange firstMatchRange = [self.pathMatcher rangeOfFirstMatchInString:input options:options range:range];
    if (firstMatchRange.location == NSNotFound) {
        return nil;
    }

    NSString *output = [self.pathMatcher stringByReplacingMatchesInString:input options:options range:range withTemplate:self.replacementPattern];
    NSURL *url = [NSURL URLWithString:output];

    return url;
}



#pragma mark - equality
-(NSUInteger)hash
{
    NSUInteger hash = [BCLRedirectingURLCacheRedirectionRule hash];
    hash ^= self.pathMatchingRegex.hash;
    hash ^= self.replacementPattern.hash;

    return hash;
}



-(BOOL)isEqual:(BCLRedirectingURLCacheRedirectionRule *)object
{
    if (![object isKindOfClass:[BCLRedirectingURLCacheRedirectionRule class]]) {
        return NO;
    }

    if (![[object method] isEqualToString:self.method]) {
        return NO;
    }

    if (![[object pathMatchingRegex] isEqualToString:self.pathMatchingRegex]) {
        return NO;
    }

    if (![[object replacementPattern] isEqualToString:self.replacementPattern]) {
        return NO;
    }

    return YES;
}


#pragma mark - debugging
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p {pathMatchingRegex: %@; resourcePath: %@;}>", NSStringFromClass(self.class), self, self.pathMatchingRegex, self.replacementPattern];
}

@end
