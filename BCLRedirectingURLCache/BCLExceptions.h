//
//  BCLExceptions.h
//  BCLRedirectingURLCache
//
//  Created by Benedict Cohen on 18/05/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#ifndef BCLRedirectingURLCache_BCLExceptions_h
#define BCLRedirectingURLCache_BCLExceptions_h


#define __BLCTokenToString(TOKEN) __BLCTokenToStringInternals(TOKEN)
#define __BLCTokenToStringInternals(s) #s

#define BCLExpect(CONDITION, FORMAT_AND_ARGS...)  do {if (!(CONDITION))        { [NSException raise:NSInvalidArgumentException format:FORMAT_AND_ARGS]; }} while (NO)
#define BCLExpectParameter(PARAMETER) do {if ( (PARAMETER) == nil) { [NSException raise:NSInvalidArgumentException format:@"Failed parameter expectation: Expected %s to be non-nil.", __BLCTokenToString(PARAMETER) ]; }} while (NO)

#endif
