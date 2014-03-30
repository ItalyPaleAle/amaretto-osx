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

#import "AMCommon.h"


@interface AMUIController ()

// Private methods
- (NSDictionary*)performRequestWithMethod:(NSString*)method args:(NSDictionary*)args;
- (void)request:(NSString*)method args:(WebScriptObject*)args callback:(WebScriptObject*)callback;
- (void)syncRequest:(NSString*)method args:(WebScriptObject*)args callback:(WebScriptObject*)callback;
- (void)executeCallback:(AMJSCallback*)jscallback;
- (void)setJSMainCallback:(WebScriptObject*)callback;

@end



@implementation AMUIController

- (void)loadMainUI
{
	// Prepare the view
	self.mainWebView.mainFrame.frameView.allowsScrolling = NO;
	self.mainWebView.UIDelegate = self;
	self.mainWebView.frameLoadDelegate = self;
	
	// Load page
	NSURL *URL = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"ui"];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	[self.mainWebView.mainFrame loadRequest:request];
}

- (void)sendMessage:(NSDictionary*)args
{
	AMJSCallback *exec = [AMJSCallback new];
	exec.callback = self.mainCallback.callback;
	exec.data = args;
	[self performSelectorOnMainThread:@selector(executeCallback:) withObject:exec waitUntilDone:NO];
}

- (NSDictionary*)performRequestWithMethod:(NSString*)method args:(NSDictionary*)args
{
	NSString *error = nil;
	NSString *errorString = @"";
	id<NSObject> payload = nil;
	
	@try
	{
		NSString *routesFile = [[NSBundle mainBundle] pathForResource:@"Routes" ofType:@"plist"];
		NSDictionary *routes = [NSDictionary dictionaryWithContentsOfFile:routesFile];
		
		NSString *className = [routes objectForKey:method];
		if(!className || [className isEqualToString:@""])
		{
			@throw [NSException exceptionWithName:@"RoutingError" reason:@"Request method not defined" userInfo:nil];
		}
		
		id<AMRouteProtocol> routeObj = [NSClassFromString(className) new];
		if(!routeObj)
		{
			@throw [NSException exceptionWithName:@"RoutingError" reason:[NSString stringWithFormat:@"Class %@ not existing", className, nil] userInfo:nil];
		}
		
		payload = [routeObj executeMethod:method withArgs:args];
	}
	@catch (NSException *exception)
	{
		error = exception.name;
		errorString = exception.reason;
		payload = nil;
	}
	
	NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
							(error ? error : [NSNumber numberWithInt:0]), @"error",
							(errorString ? errorString : @""), @"errorString",
							(payload ? payload : [NSDictionary dictionary]), @"data",
							nil];
		
	return result;
}

- (void)executeCallback:(AMJSCallback*)jscallback
{
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
	
	JSStringRef string = JSStringCreateWithCFString((__bridge CFStringRef)stringValue);
	JSValueRef args = JSValueMakeFromJSONString(ctx, string);
	
	if(args)
	{
		JSObjectCallAsFunction(ctx, ref, NULL, 1, &args, NULL);
	}
}

// Async version
- (void)request:(NSString*)method args:(WebScriptObject*)args callback:(WebScriptObject*)callback
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

// Sync version
- (void)syncRequest:(NSString*)method args:(WebScriptObject*)args callback:(WebScriptObject*)callback
{
	JSContextRef ctx = [self.mainWebView.mainFrame globalContext];
	JSObjectRef argsRef = [args JSObject];
	NSDictionary *argsDict = JSObjectToNSDictionary(ctx, argsRef);
	
	//[NSThread sleepForTimeInterval:2.0f];
	
	AMJSCallback *cb = [AMJSCallback new];
	cb.callback = callback;
	cb.data = [self performRequestWithMethod:method args:argsDict];
	[self performSelectorOnMainThread:@selector(executeCallback:) withObject:cb waitUntilDone:NO];
}

- (void)setJSMainCallback:(WebScriptObject*)callback
{
	AMJSCallback *cb = [AMJSCallback new];
	cb.callback = callback;
	cb.data = nil;
	
	self.mainCallback = cb;
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
	if(sel == @selector(request:args:callback:) ||
	   sel == @selector(syncRequest:args:callback:) ||
	   sel == @selector(setJSMainCallback:))
	{
		return NO;
	}
	return YES;
}

+(NSString*)webScriptNameForSelector:(SEL)sel
{
	if(sel == @selector(request:args:callback:))
	{
		return @"request";
	}
	else if(sel == @selector(syncRequest:args:callback:))
	{
		return @"syncRequest";
	}
	else if(sel == @selector(setJSMainCallback:))
	{
		return @"setMainCallback";
	}
	return nil;
}

// Disable contextual menu (right click)
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil;
}
@end
