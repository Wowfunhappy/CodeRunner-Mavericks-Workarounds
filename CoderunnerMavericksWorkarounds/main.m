#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"




@interface myWindowController : NSWindowController
@end


@implementation myWindowController

//If tab bar is hidden in full screen while toolbar is visible, an annoying visual anomaly appears.

- (void)setTabBarHidden:(BOOL)arg1 updateDefaultsValue:(BOOL)arg2 {
    if (arg1) {
        //Tab bar will hide.
        NSWindow *window = [self window];
        if ([window styleMask] & NSFullScreenWindowMask && [[window toolbar] isVisible]) {
            [[window toolbar] hackToRemoveTabBarRemnant];
        }
    }
    ZKOrig(void, arg1, arg2);
}
@end




@interface myNSToolbar : NSToolbar
@end


@implementation myNSToolbar

//Todo: find some type of toolbar update or redraw method which works instead of actually toggling the toolbar!
- (void)hackToRemoveTabBarRemnant {
    NSDisableScreenUpdates();
    [self setVisible:false];
    [self performSelector:@selector(showToolBarThenEnableScreenUpdates) withObject:nil afterDelay:0.001];
}
- (void)showToolBarThenEnableScreenUpdates {
    [self setVisible:true];
    [self performSelector:@selector(enableScreenUpdates) withObject:nil afterDelay:0.02];
}
- (void)enableScreenUpdates {
    NSEnableScreenUpdates();
}

@end




@interface myNSWindow : NSWindow
@end


@implementation myNSWindow

- (void)toggleFullScreen:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSTextFinderIndicatorManagerShouldSetNotVisible" object:nil];
    ZKOrig(void, sender);
}

@end




@interface myNSTabView : NSTabView
@end


@implementation myNSTabView

- (void)selectTabViewItem:(id)arg1 {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSTextFinderIndicatorManagerShouldSetNotVisible" object:nil];
    ZKOrig(void, arg1);
}

- (void)removeTabViewItem:(id)arg1 {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSTextFinderIndicatorManagerShouldSetNotVisible" object:nil];
    ZKOrig(void, arg1);
}

@end




/* Fixes problems which occur when the user searches for text, then switches tabs while a term is highlighted. */

@interface myNSTextFinderIndicatorManager : NSObject
- (void)setIsVisible:(BOOL)arg1 animate:(BOOL)arg2;
@end


@implementation myNSTextFinderIndicatorManager

- (id)initWithTextFinderImpl:(id)arg1 {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNotVisible) name:@"NSTextFinderIndicatorManagerShouldSetNotVisible" object:nil];
    return ZKOrig(id, arg1);
}

- (void)setNotVisible {
    [self setIsVisible:false animate:false];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NSTextFinderIndicatorManagerShouldSetNotVisible" object:nil];
    [super dealloc];
}

@end




/* Fixes most crashes, such as when the user opens Preferences.
 
 The crash log said the app crashed because signatureWithObjCTypes's type signature was empty.
 So I made it so it can't be empty. And now the app doesn't crash. Okay. */

@interface myNSMethodSignature : NSObject
@end


@implementation myNSMethodSignature

+ (id)signatureWithObjCTypes:(const char *)types {
    if (strcmp(types, "") == 0) {
        return nil;
    }
    return ZKOrig(id, types);
}

@end




/* Fixes a problem which occurs when the user (1) saves and closes a FooLanguage file,
 (2) disables FooLanguage in CodeRunner Preferences, and (3) re-opens the FooLanguage file. */

@interface myNSMenu : NSView
@end


@implementation myNSMenu

- (NSInteger)indexOfItemWithTitle:(NSString *)title {
    if (!title) {
        return 0;
    }
    return ZKOrig(NSInteger, title);
}

@end



BOOL shouldPreventNSAttributeDictionaryRelease; //Warning: global variable!

@interface myEditor : NSTextView
@end


@implementation myEditor

/*
 Highlight matching parenthesis/brackets (for more than a few seconds).
 Not technically a bug fix, but a feature I need!
 */

- (void)showFindIndicatorForRange:(NSRange)charRange {
    ZKOrig(void, charRange);
    if ([[self textStorage] length] > 0) {
        [[self textStorage] addAttribute:NSBackgroundColorAttributeName
                                   value:[NSColor colorWithCalibratedWhite:0.5 alpha:0.4]
                                   range:charRange];
        
        NSValue *rangeValue = [NSValue valueWithRange:charRange];
        objc_setAssociatedObject(self, @selector(lastMatchHighlight), rangeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setSelectedRanges:(id)arg1 affinity:(unsigned long long)arg2 stillSelecting:(BOOL)arg3{
    ZKOrig(void, arg1, arg2, arg3);
    NSRange lastMatchHighlight = [objc_getAssociatedObject(self, @selector(lastMatchHighlight)) rangeValue];
    if (NSMaxRange(lastMatchHighlight) <= [[self textStorage] length]) {
        [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:lastMatchHighlight];
    }
}

//Also not a bug, but CodeRunner overrides OS X's default `look up in dictionary` functionality to search documentation.
//Let's make it not do that.
- (void)quickLookWithEvent:(id)arg1 {
    [super quickLookWithEvent:arg1];
}

/*
 CodeRunner crashes when the user tries to print (As in, to a paper printer.)
 
 The crash is caused by a use-after-free error. We can fix it crudely by temporarily no-op'ing NSAttributeDictionary's release
 method. This is kind of ugly, but the amount of memory leaked is exceedingly trivial.
 */

- (void)print:(id)arg1 {
    NSLog(@"CodeRunnerMavericksWorkarounds: Intentionally forcing CodeRunner to leak memory to avert a crash.");
    shouldPreventNSAttributeDictionaryRelease = true;
    ZKOrig(void, arg1);
    shouldPreventNSAttributeDictionaryRelease = false;
}

@end




@interface myNSAttributeDictionary : NSObject
@end


@implementation myNSAttributeDictionary

- (oneway void)release {
    if (shouldPreventNSAttributeDictionaryRelease) {
        //See above; leak the memory instead of freeing it.
        return;
    }
    ZKOrig(void);
}

@end




@interface myNSUserDefaults : NSObject
@end


@implementation myNSUserDefaults

// For some reason, CodeRunner reads the preferred scrollbar style from NSUserDefaults instead of using [NSScroller preferredScrollerStyle].
// This causes problems if scrollbars are set to "Automatic", but the user is using a mouse rather than a Trackpad.
// When CodeRunner queries NSUserDefaults, we'll look at [NSScroller preferredScrollerStyle] instead and respond accordingly.

- (id)objectForKey:(NSString *)defaultName {
    if ([defaultName isEqual: @"AppleShowScrollBars"]) {
        // Problem: [NSScroller preferredScrollerStyle] will itself read AppleShowScrollBars from NSUserDefaults, causing infinite recursion!
        // Don't call [NSScroller preferredScrollerStyle] unless this method is invoked by CodeRunner itself (versus AppKit).
        NSString *caller = [[[NSThread callStackSymbols] objectAtIndex:1] substringWithRange:NSMakeRange(4, 10)];
        if ([caller isEqualToString:@"CodeRunner"]) {
            if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy) {
                return @"Always";
            } else {
                return @"WhenScrolling";
            }
        }
    }
    return ZKOrig(id, defaultName);
}

@end




@interface myConsoleTextView : NSTextView
@end


@implementation myConsoleTextView

//Without this fix, it's difficult to scroll up in a console which outputs lots of text quickly.
//I'm not sure if this is Mavericks-specific, but it's annoying and worth fixing.

- (BOOL)shouldScrollToBottom {
    NSRect visibleRect = [[self.enclosingScrollView contentView] documentVisibleRect];
    NSRect bounds = [[self.enclosingScrollView documentView] bounds];
    
    if (NSMaxY(visibleRect) >= NSMaxY(bounds) - 3) {
        return true;
    } else {
        return false;
    }
}

@end




@interface Process : NSObject
@end

@interface myProcessManager : NSObject
@end

@implementation myProcessManager

/*
 An intermittent bug which has been driving me crazy for years: at some point after you've been using
 CodeRunner for a while (running and editing different code and on), you'll press the run button but
 nothing will appear in the console window, and CodeRunner will begin consuming a huge amount of CPU.
 You can cancel and re-run the script, which might work that time, but the problem will become
 increasingly frequent until you restart CodeRunner.
 
 The problem has something to do with this mainLoop method. This is my third attempt to fix this bug,
 so I'm going to just reimplement the whole method with a super simple version. The original (I think)
 used file descriptors to only read when there was new data available, but we're just going to read after
 a fixed time interval. And if I encounter the bug again after all of this, I am going to scream...
 */

-(void)mainLoop {
    while (![[NSThread currentThread] isCancelled]) {
        @autoreleasepool {
            while ([[self getProcesses] count] > 0) {
                @autoreleasepool {
                    for (Process *process in [self getProcesses]) {
                        [process read];
                        if ([process shouldWrite]) {
                            [process write];
                        }
                        [NSThread sleepForTimeInterval:0.005];
                    }
                }
            }
            [NSThread sleepForTimeInterval:0.1];
        }
    }
}

- (NSRecursiveLock*)getLock {
    return ZKHookIvar(self, NSRecursiveLock *, "lock");
}

- (NSMutableArray*)getProcesses {
    NSRecursiveLock *lock = [self getLock];
    [lock lock];
    NSMutableArray *processesCopy = [ZKHookIvar(self, NSMutableArray *, "processes") copy];
    [lock unlock];
    return processesCopy;
}

@end




@interface myDocument : NSDocument
{
    NSView *documentView;
}
@end


@implementation myDocument

//Normally, notifications will only appear if the CodeRunner window is not in focus.
//We want notifications to always appear, because the running tab may not be in focus even if the window is.

- (void)deliverUserNotificationWithTitle:(id)titleText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = titleText;
    notification.informativeText = [self fullDisplayName];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

@end




@interface myAppDelegate : NSObject
@end

@implementation myAppDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return true;
}

@end




@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myWindowController, WindowController);
    ZKSwizzle(myNSToolbar, NSToolbar);
    ZKSwizzle(myNSWindow, NSWindow);
    ZKSwizzle(myNSTabView, NSTabView);
    ZKSwizzle(myNSTextFinderIndicatorManager, NSTextFinderIndicatorManager);
    ZKSwizzle(myNSMethodSignature, NSMethodSignature);
    ZKSwizzle(myNSMenu, NSMenu);
    ZKSwizzle(myEditor, Editor);
    ZKSwizzle(myNSAttributeDictionary, NSAttributeDictionary);
    ZKSwizzle(myNSUserDefaults, NSUserDefaults);
    ZKSwizzle(myConsoleTextView, ConsoleTextView);
    ZKSwizzle(myProcessManager, ProcessManager);
    ZKSwizzle(myDocument, Document);
    ZKSwizzle(myAppDelegate, AppDelegate);
}

@end
