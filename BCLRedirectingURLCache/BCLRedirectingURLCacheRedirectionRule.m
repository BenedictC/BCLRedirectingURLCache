//
//  BCLRedirectingURLCacheRedirectionRule.m
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 08/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCLRedirectingURLCacheRedirectionRule.h"



@interface BCLRedirectingURLCacheRedirectionRule ()
@property(readonly) NSPredicate *methodMatcher;
@property(readonly) NSRegularExpression *pathMatcher;
@end




@implementation BCLRedirectingURLCacheRedirectionRule

#pragma mark - factory methods
+(NSArray *)redirectRulesFromContentsOfFile:(NSString *)path baseURL:(NSURL *)baseURL
{
    if (path == nil) {
        return @[];
    }

    NSString *redirectRulesContent = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:NULL];
    return [self scanRedirectRulesFromString:redirectRulesContent baseURL:baseURL path:path];
}



+(NSArray *)redirectRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL
{
    return [self scanRedirectRulesFromString:string baseURL:baseURL path:nil];
}



#pragma mark - parsing
#define BCLRaiseIf(CONDITION, FORMAT, ...) if (!(CONDITION)) {     [NSException raise:NSInvalidArgumentException format:FORMAT, __VA_ARGS__ ]; }
+(NSArray *)scanRedirectRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL path:(NSString *)redirectRulesPath
{
    NSParameterAssert(string);
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    NSMutableArray *redirectRules = [NSMutableArray new];
    while ([self scanCommentsAndWhitespace:scanner]) {
        NSString *method = nil;
        BOOL didScanMethod = [self scanMethodRegexFromScanner:scanner intoString:&method];
        BCLRaiseIf(didScanMethod, @"Failed to scan method for RedirectRule at character %@ of %@: %@", @(scanner.scanLocation), redirectRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];

        NSString *regex = nil;
        BOOL didScanRegex = [self scanURLRegexFromScanner:scanner intoString:&regex];
        BCLRaiseIf(didScanRegex, @"Failed to scan regex for RedirectRule at character %@ of %@: %@", @(scanner.scanLocation), redirectRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];

        NSString *replacementPattern = nil;
        BOOL didScanReplacementPattern = [self scanReplacementPatternFromScanner:scanner intoString:&replacementPattern];
        BCLRaiseIf(didScanReplacementPattern, @"Failed to scan replacementPattern for RedirectRule at character %@ of %@: %@", @(scanner.scanLocation), redirectRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        //Scan trailing comment and the terminal new line
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
        if ([scanner scanString:@"#" intoString:NULL]) {
            [scanner scanUpToString:@"\n" intoString:NULL];
        }
        BOOL didScanNewline = [scanner scanString:@"\n" intoString:NULL];
        BCLRaiseIf(didScanNewline || scanner.isAtEnd, @"Unexpected text found at end of RedirectRule line at character %@ of %@: %@", @(scanner.scanLocation), redirectRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        //Add the scanned rule
        BCLRedirectingURLCacheRedirectionRule *redirectRule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethodRegex:method URLRegex:regex URLReplacementPattern:replacementPattern baseURL:baseURL];
        [redirectRules addObject:redirectRule];
    }

    return [redirectRules copy];
}



+(BOOL)scanCommentsAndWhitespace:(NSScanner *)scanner
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



+(BOOL)scanMethodRegexFromScanner:(NSScanner *)scanner intoString:(NSString **)method
{
    NSParameterAssert(method);

    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:method]) {
        //If there's no whitespace then the scan failed
        BOOL didScanWhitespace = [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        return didScanWhitespace;
    }

    return NO;
}



+(BOOL)scanURLRegexFromScanner:(NSScanner *)scanner intoString:(NSString **)regex
{
    return [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:regex];
}



+(BOOL)scanReplacementPatternFromScanner:(NSScanner *)escappedScanner intoString:(NSString **)outReplacementPattern
{
    NSString *escapedPattern = nil;
    if (![escappedScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&escapedPattern]) {
        return NO;
    }

    NSScanner *scanner = [NSScanner scannerWithString:escapedPattern];
    NSMutableString *replacementPattern = [NSMutableString new];
    NSString *buffer = nil;
    while ([scanner scanUpToString:@"\\" intoString:&buffer]) {
        [replacementPattern appendString:buffer];

        //Scan past openning slashing
        if (![scanner scanString:@"\\" intoString:NULL]) {
            //If the scan failed then we entered the loop because the scanner was at the end of the string.
            break;
        }

        if ([scanner scanString:@"\\" intoString:NULL]) {
            [replacementPattern appendString:@"\\"];
        } else if ([scanner scanString:@"t" intoString:NULL]) {
            [replacementPattern appendString:@"\t"];
        } else if ([scanner scanString:@"s" intoString:NULL]) {
            [replacementPattern appendString:@" "];
        } else if ([scanner scanString:@"n" intoString:NULL]) {
            [replacementPattern appendString:@"\n"];
        } else {
            //TODO: Improve reporting
            NSAssert(NO, @"Unrecognized escape sequence.");
        }
    }

    *outReplacementPattern = [replacementPattern copy];
    return YES;
}



#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithMethodRegex:nil URLRegex:nil URLReplacementPattern:nil baseURL:nil];
}



-(instancetype)initWithMethodRegex:(NSString *)methodRegex URLRegex:(NSString *)URLRegex URLReplacementPattern:(NSString *)replacementPattern baseURL:(NSURL *)baseURL;
{
    NSParameterAssert(methodRegex);
    NSParameterAssert(URLRegex);
    NSParameterAssert(replacementPattern);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _methodRegex = methodRegex;
    _URLRegex = [URLRegex copy];
    _URLReplacementPattern = [replacementPattern copy];
    _baseURL = baseURL;

    _methodMatcher = [NSPredicate predicateWithFormat:@"self MATCHES %@", _methodRegex];
    NSError *error;
    _pathMatcher = [[NSRegularExpression alloc] initWithPattern:URLRegex options:0 error:&error];
    NSAssert(_pathMatcher != nil, @"\\%@\\ in not a valid regular expression: %@", URLRegex, error);


    return self;
}



#pragma mark - evaluation
-(NSURL *)resolvedURLForRequest:(NSURLRequest *)request
{
    NSParameterAssert(request);

    BOOL didMatchMethod = [self.methodMatcher evaluateWithObject:request.URL];
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

    NSString *output = [self.pathMatcher stringByReplacingMatchesInString:input options:options range:range withTemplate:self.URLReplacementPattern];

    NSURL *url = (self.baseURL == nil) ? [NSURL URLWithString:output] : [self.baseURL URLByAppendingPathComponent:output];

    return url;
}



#pragma mark - equality
-(NSUInteger)hash
{
    NSUInteger hash = [BCLRedirectingURLCacheRedirectionRule hash];
    hash ^= self.URLRegex.hash;
    hash ^= self.URLReplacementPattern.hash;

    return hash;
}



-(BOOL)isEqual:(BCLRedirectingURLCacheRedirectionRule *)object
{
    if (![object isKindOfClass:[BCLRedirectingURLCacheRedirectionRule class]]) {
        return NO;
    }

    if (![[object methodRegex] isEqualToString:self.methodRegex]) {
        return NO;
    }

    if (![[object URLRegex] isEqualToString:self.URLRegex]) {
        return NO;
    }

    if (![[object URLReplacementPattern] isEqualToString:self.URLReplacementPattern]) {
        return NO;
    }

    BOOL isMatchingBaseURLs = ([object baseURL] == nil && [self baseURL] == nil) || [[object baseURL] isEqual:self.baseURL];
    if (!isMatchingBaseURLs) {
        return NO;
    }

    return YES;
}



#pragma mark - debugging
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p {URLRegex: %@; resourcePath: %@; baseURL: %@}>", NSStringFromClass(self.class), self, self.URLRegex, self.URLReplacementPattern, self.baseURL];
}

@end
