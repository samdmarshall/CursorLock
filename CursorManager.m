//
//  CursorManager.m
//  CursorLock
//
//  Created by sam on 9/19/12.
//  Copyright 2012 Sam Marshall. All rights reserved.
//

#import "CursorManager.h"

pid_t GetPIDFromDictionary(CFDictionaryRef dict, CFStringRef key) {
	long pid;
	CFNumberRef cf_pid = CFDictionaryGetValue(dict, key);
	CFNumberGetValue(cf_pid, CFNumberGetType(cf_pid), &pid);
	return pid;
}

CGRect GetRectFromWindowDescription(CFDictionaryRef dict) {
	float x = [[(NSDictionary *)dict objectForKey:@"X"] floatValue];
	float y = [[(NSDictionary *)dict objectForKey:@"Y"] floatValue];
	float w = [[(NSDictionary *)dict objectForKey:@"Width"] floatValue];
	float h = [[(NSDictionary *)dict objectForKey:@"Height"] floatValue];
	return CGRectMake(x,y,w,h);
}

CFArrayRef GetWindowsForProcessWithPID(pid_t pid) {
	ProcessSerialNumber psn;
	OSStatus result = GetProcessForPID(pid, &psn);
	if (result == 0) {
		CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
		CFMutableArrayRef app_windows = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
		for (int b = 0; b < CFArrayGetCount(windows); b++) {
			CFDictionaryRef dict = CFArrayGetValueAtIndex(windows, b);
			pid_t window_pid = GetPIDFromDictionary(dict, kCGWindowOwnerPID);
			if (window_pid == pid) {
				CFArrayAppendValue(app_windows, dict);
			}
		}
		return app_windows;
	} else {
		return NULL;
	}
}

CGPoint GetCenterOfRect(CGRect rect) {
	return CGPointMake(rect.origin.x+(rect.size.width/2), rect.origin.y+(rect.size.height/2));
}

@implementation CursorManager

static CGRect window_center;

@synthesize applicationList;
@synthesize lockButton;
@synthesize refreshButton;
@synthesize status;
@synthesize applications;
@synthesize cprocess;
@synthesize reset_timer;
@synthesize windowList;
@synthesize window_dictionaries;

- (id)initWithWindow:(NSWindow *)window {
	self = [super init];
	if (self) {
		status = FALSE;
		window_center = [[window screen] frame];
	}
	return self;
}

- (void)awakeFromNib {
	[self refreshApps:nil];
	window_dictionaries = [NSMutableArray new];
}

- (void)updateApps {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	applications = [[[NSWorkspace sharedWorkspace] runningApplications] copy];
	[applicationList removeAllItems];
	[windowList removeAllItems];
	for (NSRunningApplication *app in applications) {
		[applicationList addItemWithTitle:[app localizedName]];
	}
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didActivate:) name:@"NSWorkspaceDidActivateApplicationNotification" object:nil];
}

- (IBAction)toggleLock:(id)sender {
	NSPredicate *get_app = [NSPredicate predicateWithFormat:@"localizedName contains %@",[applicationList titleOfSelectedItem]];
	NSArray *the_app = [applications filteredArrayUsingPredicate:get_app];
	if (the_app.count) {
		cprocess = [[the_app objectAtIndex:0] processIdentifier];
		[applicationList setEnabled:status];
		[windowList setEnabled:status];
		[refreshButton setEnabled:status];
		[lockButton setTitle:(status? @"Lock" : @"Unlock")];
		status = !status;
	} else {
		[self updateApps];
	}
}

- (IBAction)refreshApps:(id)sender {
	[self updateApps];
}

- (IBAction)updateWindowList:(id)sender {
	NSPredicate *get_app = [NSPredicate predicateWithFormat:@"localizedName contains %@",[applicationList titleOfSelectedItem]];
	NSArray *the_app = [applications filteredArrayUsingPredicate:get_app];
	if (the_app.count) {
		cprocess = [[the_app objectAtIndex:0] processIdentifier];
		NSArray *windows = (NSArray *)GetWindowsForProcessWithPID(cprocess);
		[windowList removeAllItems];
		[window_dictionaries removeAllObjects];
		for (NSDictionary *window_dict in windows) {
			if (CFDictionaryContainsKey((CFDictionaryRef)window_dict, kCGWindowName)) {
				[window_dictionaries addObject:window_dict];
				NSString *name = CFDictionaryGetValue((CFDictionaryRef)window_dict, kCGWindowName);
				[windowList addItemWithTitle:name];
			}
		}
		if ([windowList itemArray].count) {
			[windowList selectItemAtIndex:0];
			[self updateBoundsSilent];
		}
	} else {
		
	}
}

- (IBAction)updateWindowBounds:(id)sender {
	[self updateBoundsSilent];
}

- (void)updateBoundsSilent {
	NSDictionary *window_props = [window_dictionaries objectAtIndex:[windowList indexOfSelectedItem]];
	window_center = GetRectFromWindowDescription(CFDictionaryGetValue((CFDictionaryRef)window_props, kCGWindowBounds));
}

- (void)didActivate:(NSNotification *)notif {
	pid_t current;
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	GetFrontProcess(&psn);
	GetProcessPID(&psn, &current);
	if (current == cprocess) {
		reset_timer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(resetCursorPosition:) userInfo:nil repeats:YES] retain];
	}
}

- (void)resetCursorPosition:(NSTimer *)timer {
	pid_t current;
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	GetFrontProcess(&psn);
	GetProcessPID(&psn, &current);
	if (current != cprocess || !status) {
		[timer invalidate];
		ProcessSerialNumber active_psn;
		NSInteger process_check = GetProcessForPID(cprocess, &active_psn);
		if (process_check == -600) {
			[self toggleLock:nil];
			[self refreshApps:nil];
		}
	} else {
			CGEventRef mouse_event = CGEventCreate(nil);
		CGPoint mouse = CGEventGetLocation(mouse_event);
		if (!CGRectContainsPoint(window_center, mouse)) {
			CGFloat x = mouse.x, y = mouse.y;
			if (mouse.x > window_center.origin.x+window_center.size.width - 10) {
				x = window_center.origin.x+window_center.size.width - 15;
			} else if (mouse.x < window_center.origin.x - 10) {
				x = window_center.origin.x + 15;
			} else {
				x = mouse.x;
			}
			if (mouse.y < window_center.origin.y + 20) {
				y = window_center.origin.y + 25;
			} else if (mouse.y > window_center.origin.y+window_center.size.height - 10) {
				y = window_center.origin.y+window_center.size.height - 15;
			} else {
				y = mouse.y;
			}
			CGWarpMouseCursorPosition((CGPoint){x,y});
		}
		CFRelease(mouse_event);
	}
}

- (void)dealloc {
	[applicationList release];
	[lockButton release];
	[refreshButton release];
	[applications release];
	[windowList release];
	[window_dictionaries release];
	if ([reset_timer isValid]) {
		[reset_timer invalidate];
	}
	[reset_timer release];
	[super dealloc];
}


@end