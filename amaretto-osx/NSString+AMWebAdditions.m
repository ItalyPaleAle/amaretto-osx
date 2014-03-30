/*
 NSString+AMWebAdditions.m
 amaretto-osx
 
 Copyright (c) 2014 EgoAleSum
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSString+AMWebAdditions.h"

@implementation NSString (AMWebAdditions)

- (NSDictionary*)decodeHTTPQueryString
{
	NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
	NSArray *allParams = [self componentsSeparatedByString:@"&"];
	
	for(NSString *param in allParams)
	{
		NSArray *comps = [param componentsSeparatedByString:@"="];
		NSString *key = [[comps objectAtIndex:0] decodeUrlString];
		NSString *value = [[comps objectAtIndex:1] decodeUrlString];
		
		[resultDict setObject:value forKey:key];
	}
	
	return resultDict;
}

- (NSString*)decodeUrlString
{
	return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "]
			  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
