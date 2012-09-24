//
//  CursorManager.h
//  CursorLock
//
//  Created by sam on 9/19/12.
//  Copyright 2012 Sam Marshall. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CursorManager : NSObject {
	IBOutlet NSPopUpButton *applicationList;
	IBOutlet NSPopUpButton *windowList;
	IBOutlet id lockButton;
	IBOutlet id refreshButton;
	BOOL status;
	NSArray *applications;
	pid_t cprocess;
	NSTimer *reset_timer;
	NSMutableArray *window_dictionaries;
}

@property (nonatomic, retain) IBOutlet NSPopUpButton *applicationList;
@property (nonatomic, retain) IBOutlet id lockButton;
@property (nonatomic, retain) IBOutlet id refreshButton;
@property (readonly) BOOL status;
@property (nonatomic, retain) NSArray *applications;
@property (readonly) pid_t cprocess;
@property (nonatomic, retain) NSTimer *reset_timer;
@property (nonatomic, retain) IBOutlet NSPopUpButton *windowList;
@property (nonatomic, retain) NSMutableArray *window_dictionaries;

- (id)initWithWindow:(NSWindow *)window;
- (IBAction)toggleLock:(id)sender;
- (IBAction)refreshApps:(id)sender;
- (IBAction)updateWindowList:(id)sender;
- (IBAction)updateWindowBounds:(id)sender;
- (void)updateApps;
- (void)didActivate:(NSNotification *)notif;
- (void)resetCursorPosition:(NSTimer *)timer;
- (void)updateBoundsSilent;
@end
