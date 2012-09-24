//
//  CursorLockAppDelegate.h
//  CursorLock
//
//  Created by sam on 9/19/12.
//  Copyright 2012 Sam Marshall. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CursorManager.h"

@interface CursorLockAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	CursorManager *ccontrol;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) CursorManager *ccontrol;
@end
