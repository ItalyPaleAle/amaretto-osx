/*
 AMUIController.m
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

#import "AMUIController.h"


@implementation AMUIController

- (void)loadMainUI
{
	// Prepare the view
	self.mainWebView.mainFrame.frameView.allowsScrolling = NO;
	self.mainWebView.UIDelegate = self;
	self.mainWebView.frameLoadDelegate = self;
	
	// Load page
	NSURL *URL = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	[self.mainWebView.mainFrame loadRequest:request];
}

- (NSDictionary*)performRequestWithMethod:(NSString*)method args:(NSDictionary*)args
{
	int error = 0;
	NSString *errorString = @"";
	NSDictionary *payload = nil;
	
	@try
	{
		if([method isEqualToString:@"list"])
		{
			payload = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"]; //getConversationList(args);
		}
		else
		{
			@throw [NSException exceptionWithName:@"Internal error" reason:@"Invalid request method" userInfo:nil];
		}
	}
	@catch (NSException *exception)
	{
		error = 1;
		errorString = exception.reason;
		payload = nil;
	}
	
	NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:error], @"error",
							errorString, @"errorString",
							payload, @"payload",
							nil];
		
	return result;
}

- (void)executeCallback:(AMJSCallback*)jscallback
{
	//[jscallback retain];
	
	JSContextRef ctx = [self.mainWebView.mainFrame globalContext];
	JSObjectRef ref = [jscallback.callback JSObject];
	
	NSString *stringValue;
	if([jscallback.data isKindOfClass:[NSString class]])
	{
		stringValue = (NSString*)jscallback.data;
	}
	else if([jscallback.data isKindOfClass:[NSNumber class]])
	{
		stringValue = [(NSNumber*)[jscallback data] stringValue];
	}
	else
	{
		stringValue = [[NSString alloc]
					   initWithData:[NSJSONSerialization dataWithJSONObject:jscallback.data options:0 error:NULL]
					   encoding:NSUTF8StringEncoding];
	}
	
	CFStringRef foundationString = (__bridge_retained CFStringRef)stringValue;
	JSStringRef string = JSStringCreateWithCFString(foundationString);
	JSValueRef args = JSValueMakeFromJSONString(ctx, string);
	CFRelease(foundationString);
	
	if(args)
	{
		JSObjectCallAsFunction(ctx, ref, NULL, 1, &args, NULL);
	}
	
	//[jscallback release];
}

// JavaScript-accessible methods
- (void)asyncRequest:(NSString*)method args:(WebScriptObject*)args callback:(WebScriptObject*)callback
{
	JSContextRef ctx = [self.mainWebView.mainFrame globalContext];
	JSObjectRef argsRef = [args JSObject];
	NSDictionary *argsDict = JSObjectToNSDictionary(ctx, argsRef);
	
	NSOperationQueue *queue = [[AMCommon sharedInstance] operationQueue];
	[queue addOperationWithBlock:^{
		AMJSCallback *cb = [AMJSCallback new];
		cb.callback = callback;
		cb.data = [self performRequestWithMethod:method args:argsDict];
		[self performSelectorOnMainThread:@selector(executeCallback:) withObject:cb waitUntilDone:NO];
	}];
}

// Web View frame load delegate methods
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame
{
	// The "Amaretto" object will now be available to JavaScript
	[windowScriptObject setValue:self forKey:@"Amaretto"];
}

// Scripting
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if(sel == @selector(asyncRequest:args:callback:))
	{
		return NO;
	}
	return YES;
}

+(NSString*)webScriptNameForSelector:(SEL)sel
{
	if(sel == @selector(asyncRequest:args:callback:))
	{
		return @"request";
	}
	return nil;
}

// Web View UI delegate methods
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil;
}
@end
