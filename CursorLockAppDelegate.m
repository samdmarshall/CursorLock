//
//  CursorLockAppDelegate.m
//  CursorLock
//
//  Created by sam on 9/19/12.
//  Copyright 2012 Sam Marshall. All rights reserved.
//

#import "CursorLockAppDelegate.h"

@implementation CursorLockAppDelegate

@synthesize window;
@synthesize ccontrol;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	ccontrol = [[CursorManager alloc] initWithWindow:window];
}

@end
