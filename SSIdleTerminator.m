//
//  SSIdleTerminator.m
//  sockserver
//
//  Created by System Administrator on 8/10/09.
//  Copyright (c) 2009 Sidney San Martín <s@sidneysm.com>
//  
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "SSIdleTerminator.h"
#import <asl.h>

@interface SSIdleTerminator (Private)

- (void)startIdleTimer;
- (void)stopIdleTimer;
- (void)timeOut:(NSTimer*)timer;

@end


@implementation SSIdleTerminator
static SSIdleTerminator *_sharedIdleTerminator = nil;

+ (SSIdleTerminator*)idleTerminator
{
    @synchronized(self){
        if (_sharedIdleTerminator == nil){
            [[self alloc] init]; // assignment not done here
        }
    }
    return _sharedIdleTerminator;
}
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self){
        if (_sharedIdleTerminator == nil) {
            _sharedIdleTerminator = [super allocWithZone:zone];
            return _sharedIdleTerminator;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
- (id)retain
{
    return self;
}
- (NSUInteger)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}
- (void)release
{
    //do nothing
}
- (id)autorelease
{
    return self;
}
- (id)init
{
	if ((self = [super init])) {
		_activeCount = 1;
	}
	return self;
	
}
- (void)dealloc
{
	[self stopIdleTimer];
	[super dealloc];
}
- (NSTimeInterval)timeout
{
	return _timeout;
}
- (id)setTimeout:(NSTimeInterval)timeout
{
	_timeout = timeout;
	if(_activeCount == 0){
		[self startIdleTimer];
	}
	return self;
}
- (void)becomeIdle{
	if (_activeCount == 1)
		[self startIdleTimer];
	else if (_activeCount == 0){
		[NSException raise:NSInternalInconsistencyException format:@"-[SSIdleTerminator becomeIdle]: already idle"];
		return;
	}
	_activeCount--;
}
- (void)becomeActive{
	if (_activeCount == 0)
		[self stopIdleTimer];
	_activeCount++;
}
- (void)startIdleTimer{
	[self stopIdleTimer];
	if(_timeout){
		_terminationTimer = [[NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(timeOut:) userInfo:nil repeats:NO] retain];
	}
}
- (void)stopIdleTimer{
	[_terminationTimer invalidate];
	[_terminationTimer release];
	_terminationTimer = nil;
}
- (void)timeOut:(NSTimer*)timer{
	exit(EXIT_SUCCESS);
}
@end
