/*
 JavaScriptCore+AMAdditions.m
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

#import "JavaScriptCore+AMAdditions.h"

NSDictionary *JSObjectToNSDictionary(JSContextRef ctx, JSObjectRef argsRef)
{
	NSMutableDictionary *argsDict = nil;
	
	if(argsRef && JSValueIsObject(ctx, argsRef))
	{
		JSPropertyNameArrayRef properties = JSObjectCopyPropertyNames(ctx, argsRef);
		if(properties)
		{
			unsigned long count = JSPropertyNameArrayGetCount(properties);
			
			argsDict = [NSMutableDictionary dictionaryWithCapacity:count];
			
			int i;
			for(i = 0; i < count; i++)
			{
				JSStringRef propertyName = JSPropertyNameArrayGetNameAtIndex(properties, i);
				if(!propertyName)
				{
					continue;
				}
				
				CFStringRef propertyNameString = JSStringCopyCFString(kCFAllocatorDefault, propertyName);
				if(!propertyNameString)
				{
					continue;
				}
				
				JSValueRef value = JSObjectGetProperty(ctx, argsRef, propertyName, NULL);
				JSType type = JSValueGetType(ctx, value);
				
				NSObject *storeValue = nil;
				switch (type)
				{
					case kJSTypeUndefined:
					case kJSTypeNull:
					case kJSTypeObject: // We are not ready to convert objects yet
						storeValue = [NSNull null];
						break;
					
					case kJSTypeBoolean:
						storeValue = [NSNumber numberWithBool:JSValueToBoolean(ctx, value)];
						break;
						
					case kJSTypeNumber:
						storeValue = [NSNumber numberWithDouble:JSValueToNumber(ctx, value, NULL)];
						break;
					
					case kJSTypeString:
						{
							JSStringRef jsStr = JSValueToStringCopy(ctx, value, NULL);
							if(jsStr)
							{
								storeValue = (__bridge_transfer NSString *)JSStringCopyCFString(NULL, jsStr);
								JSStringRelease(jsStr);
							}
						}
						break;
				}
				
				[argsDict setObject:storeValue forKey:(__bridge NSString*)propertyNameString];
				
				CFRelease(propertyNameString);
			}
			
			JSPropertyNameArrayRelease(properties);
		}
	}
	
	return argsDict;
}
