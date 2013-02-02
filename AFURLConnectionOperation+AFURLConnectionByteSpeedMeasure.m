//
//  AFURLConnectionOperation+AFURLConnectionByteSpeedMeasure.m
//
//  Created by Oliver Letterer on 27.01.13.
//  Copyright (c) 2013 Oliver Letterer. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFURLConnectionOperation+AFURLConnectionByteSpeedMeasure.h"
#import <objc/runtime.h>

char *const AFURLConnectionOperationAFURLConnectionByteSpeedMeasureDownloadSpeedMeasureKey;
char *const AFURLConnectionOperationAFURLConnectionByteSpeedMeasureUploadSpeedMeasureKey;

static inline void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}


@implementation AFURLConnectionOperation (AFURLConnectionByteSpeedMeasure)

#pragma mark - setters and getters

- (AFURLConnectionByteSpeedMeasure *)downloadSpeedMeasure
{
    return objc_getAssociatedObject(self, &AFURLConnectionOperationAFURLConnectionByteSpeedMeasureDownloadSpeedMeasureKey);
}

- (AFURLConnectionByteSpeedMeasure *)uploadSpeedMeasure
{
    return objc_getAssociatedObject(self, &AFURLConnectionOperationAFURLConnectionByteSpeedMeasureUploadSpeedMeasureKey);
}

#pragma mark - Initialization

+ (void)load
{
    class_swizzleSelector(self, @selector(initWithRequest:), @selector(__AFURLConnectionByteSpeedMeasureInitWithRequest:));
    class_swizzleSelector(self, @selector(connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:), @selector(__AFURLConnectionByteSpeedMeasureConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:));
    class_swizzleSelector(self, @selector(connection:didReceiveData:), @selector(__AFURLConnectionConnection:didReceiveData:));
}

- (id) __attribute__((objc_method_family( init ))) __AFURLConnectionByteSpeedMeasureInitWithRequest:(NSURLRequest *)urlRequest
{
    if ((self = [self __AFURLConnectionByteSpeedMeasureInitWithRequest:urlRequest])) {
        objc_setAssociatedObject(self, &AFURLConnectionOperationAFURLConnectionByteSpeedMeasureDownloadSpeedMeasureKey,
                                 [[AFURLConnectionByteSpeedMeasure alloc] init], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &AFURLConnectionOperationAFURLConnectionByteSpeedMeasureUploadSpeedMeasureKey,
                                 [[AFURLConnectionByteSpeedMeasure alloc] init], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}

#pragma mark - NSURLConnectionDelegate

- (void)__AFURLConnectionByteSpeedMeasureConnection:(NSURLConnection *)connection
                                    didSendBodyData:(NSInteger)bytesWritten
                                  totalBytesWritten:(NSInteger)totalBytesWritten
                          totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    NSDate *now = [NSDate date];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uploadSpeedMeasure updateSpeedWithDataChunkLength:bytesWritten receivedAtDate:now];
    });
    
    [self __AFURLConnectionByteSpeedMeasureConnection:connection
                                      didSendBodyData:bytesWritten
                                    totalBytesWritten:totalBytesWritten
                            totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)__AFURLConnectionConnection:(NSURLConnection *)connection
                     didReceiveData:(NSData *)data
{
    NSUInteger length = data.length;
    NSDate *now = [NSDate date];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadSpeedMeasure updateSpeedWithDataChunkLength:length receivedAtDate:now];
    });
    
    [self __AFURLConnectionConnection:connection didReceiveData:data];
}

@end
