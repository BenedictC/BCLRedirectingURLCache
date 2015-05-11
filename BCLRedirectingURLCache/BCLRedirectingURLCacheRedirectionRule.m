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

#pragma mark - factory methods
+(NSArray *)rewriteRulesFromContentsOfFile:(NSString *)path baseURL:(NSURL *)baseURL
{
    if (path == nil) {
        return @[];
    }

    NSString *rewriteRulesContent = [NSString stringWithContentsOfFile:path usedEncoding:NULL error:NULL];
    return [self scanRewriteRulesFromString:rewriteRulesContent baseURL:baseURL path:path];
}



+(NSArray *)rewriteRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL
{
    return [self scanRewriteRulesFromString:string baseURL:baseURL path:nil];
}



#pragma mark - parsing
#define BCLRaiseIf(CONDITION, FORMAT, ...) if (!(CONDITION)) {     [NSException raise:NSInvalidArgumentException format:FORMAT, __VA_ARGS__ ]; }
+(NSArray *)scanRewriteRulesFromString:(NSString *)string baseURL:(NSURL *)baseURL path:(NSString *)rewriteRulesPath
{
    NSParameterAssert(string);
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    NSMutableArray *rewriteRules = [NSMutableArray new];
    while ([self scanCommentsAndWhitespace:scanner]) {
        NSString *method = nil;
        BOOL didScanMethod = [self scanRequestMethodFromScanner:scanner intoString:&method];
        BCLRaiseIf(didScanMethod, @"Failed to scan method for RewriteRule at character %@ of %@: %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];

        NSString *regex = nil;
        BOOL didScanRegex = [self scanPathMatchingRegexFromScanner:scanner intoString:&regex];
        BCLRaiseIf(didScanRegex, @"Failed to scan regex for RewriteRule at character %@ of %@: %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];

        NSString *replacementPattern = nil;
        BOOL didScanReplacementPattern = [self scanReplacementPatternFromScanner:scanner intoString:&replacementPattern];
        BCLRaiseIf(didScanReplacementPattern, @"Failed to scan replacementPattern for RewriteRule at character %@ of %@: %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        //Scan trailing comment and the terminal new line
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
        if ([scanner scanString:@"#" intoString:NULL]) {
            [scanner scanUpToString:@"\n" intoString:NULL];
        }
        BOOL didScanNewline = [scanner scanString:@"\n" intoString:NULL];
        BCLRaiseIf(didScanNewline || scanner.isAtEnd, @"Unexpected text found at end of RewriteRule line at character %@ of %@: %@", @(scanner.scanLocation), rewriteRulesPath ?: @"<string>", [scanner.string substringToIndex:scanner.scanLocation]);

        //Add the scanned rule
        BCLRedirectingURLCacheRedirectionRule *rewriteRule = [[BCLRedirectingURLCacheRedirectionRule alloc] initWithMethod:method pathMatchingRegex:regex replacementPattern:replacementPattern baseURL:baseURL];
        [rewriteRules addObject:rewriteRule];
    }

    return [rewriteRules copy];
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



+(BOOL)scanPathMatchingRegexFromScanner:(NSScanner *)scanner intoString:(NSString **)regex
{
    return [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:regex];
}



+(BOOL)scanRequestMethodFromScanner:(NSScanner *)scanner intoString:(NSString **)method
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
    return [self initWithMethod:nil pathMatchingRegex:nil replacementPattern:nil baseURL:nil];
}



-(instancetype)initWithMethod:(NSString *)method pathMatchingRegex:(NSString *)pathMatchingRegex replacementPattern:(NSString *)replacementPattern baseURL:(NSURL *)baseURL
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
    _baseURL = baseURL;

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

    NSURL *url = (self.baseURL == nil) ? [NSURL URLWithString:output] : [self.baseURL URLByAppendingPathComponent:output];

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

    BOOL isMatchingBaseURLs = ([object baseURL] == nil && [self baseURL] == nil) || [[object baseURL] isEqual:self.baseURL];
    if (!isMatchingBaseURLs) {
        return NO;
    }

    return YES;
}



#pragma mark - debugging
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p {pathMatchingRegex: %@; resourcePath: %@; baseURL: %@}>", NSStringFromClass(self.class), self, self.pathMatchingRegex, self.replacementPattern, self.baseURL];
}

@end
