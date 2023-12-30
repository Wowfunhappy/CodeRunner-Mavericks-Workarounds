#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"




@interface myNSTabView : NSTabView
@end


@implementation myNSTabView

- (void)selectTabViewItem:(id)arg1 {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"tabChanged" object:nil];
	ZKOrig(void, arg1);
}

- (void)removeTabViewItem:(id)arg1 {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"tabChanged" object:nil];
	ZKOrig(void, arg1);
}

@end




/* Fixes problems which occur when the user searches for text, then switches tabs while a term is highlighted. */

@interface myNSTextFinderIndicatorManager : NSObject
- (void)setIsVisible:(BOOL)arg1 animate:(BOOL)arg2;
@end


@implementation myNSTextFinderIndicatorManager

- (id)initWithTextFinderImpl:(id)arg1 {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNotVisible) name:@"tabChanged" object:nil];
	return ZKOrig(id, arg1);
}

- (void)setNotVisible {
	[self setIsVisible:false animate:false];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end




/* Fixes most crashes, such as when the user opens Preferences.
 
 I don't know why this works. I'm a simple guy. I look at the crash log, and the crash log says the app crashed because
 signatureWithObjCTypes's type signature was empty. So I made it so it can't be empty. And now the app doesn't crash. */

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




/* Fixes a problem which occurs when the user (1) saves and closes a FooLanguage file, (2) disables FooLanguage in
 CodeRunner Preferences, and (3) re-opens the FooLanguage file. */

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
 CodeRunner crashes when the user tries to print (As in, to a paper printer.)
 (I don't know who prints out their code, but accidental keypresses happen and CodeRunner should never crash!)
 
 The crash is caused by a use-after-free error. We can fix it crudely by no-op'ing NSAttributeDictionary's release
 method, but let's do so as infrequently as possible. Leaking a few bytes of memory only when the app would have
 otherwised crashed > leaking all the memory all the time.
 
 (This solution still bothers me, but hey, using Big Sur and/or Electron would waste far more memory...)
 
 Todo: Fix this...?
 */

- (void)print:(id)arg1 {
	NSLog(@"CodeRunnerMavericksWorkarounds: Intentionally forcing CodeRunner to leak memory to avert a crash.");
	shouldPreventNSAttributeDictionaryRelease = true;
	ZKOrig(void, arg1);
	shouldPreventNSAttributeDictionaryRelease = false;
}

/*
 Highlight matching parenthesis/brackets (for more than a few seconds).
 Not technically a bug fix, but a feature I need!
 */

- (void)showFindIndicatorForRange:(NSRange)charRange {
    
    [[self textStorage] addAttribute:NSBackgroundColorAttributeName
                               value:[NSColor colorWithCalibratedWhite:0.5 alpha:0.4]
                               range:charRange]; // Add new highlight
    
    NSValue *rangeValue = [NSValue valueWithRange:charRange];
    objc_setAssociatedObject(self, @selector(lastMatchHighlight), rangeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSelectedRanges:(id)arg1 affinity:(unsigned long long)arg2 stillSelecting:(BOOL)arg3{
    //remove old match highlight
    NSRange lastMatchHighlight = [objc_getAssociatedObject(self, @selector(lastMatchHighlight)) rangeValue];
    [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:lastMatchHighlight];
    
    ZKOrig(void, arg1, arg2, arg3);
}

@end




@interface myNSAttributeDictionary : NSObject
@end


@implementation myNSAttributeDictionary

- (oneway void)release {
	if (shouldPreventNSAttributeDictionaryRelease) {
		//Leak the memory instead of freeing it!
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



@interface myProcessManager : NSObject
@end


@implementation myProcessManager

- (void)addProcess:(id)arg1 {
    NSLog(@"(void)addProcess:(id)%@", arg1);
    ZKOrig(void, arg1);
}

- (void)removeProcess:(id)arg1 {
    NSLog(@"(void)removeProcess:(id)%@", arg1);
    //ZKOrig(void, arg1);
}

- (void)resume {
    NSLog(@"(void)resume");
    ZKOrig(void);
}

@end



@interface myRunner : NSObject
@end


@implementation myRunner

- (void)process:(id)arg1 didReadData:(id)arg2 {
    //NSLog(@"(void)process:(id)%@ didReadData:(id)%@", arg1, arg2);
    ZKOrig(void, arg1, arg2);
}

- (void)process:(id)arg1 didExitWithStatus:(int)arg2 time:(float)arg3; {
    NSLog(@"(void)process:(id)%@ didExitWithStatus:(int)%d time:(float)%f", arg1, arg2, arg3);
    ZKOrig(void, arg1, arg2, arg3);
}

- (void)processDidExit:(id)arg1 {
    NSLog(@"(void)processDidExit:(id)%@", arg1);
    ZKOrig(void, arg1);
}

- (void)runWithFilePath:(id)arg1 {
    NSLog(@"(void)runWithFilePath:(id)%@", arg1);
    ZKOrig(void, arg1);
}

- (void)run:(id)arg1 {
    NSLog(@"(void)run:(id)%@", arg1);
    ZKOrig(void, arg1);
}

@end



@interface myConsoleTextView : NSTextView
@end


@implementation myConsoleTextView

//Fixes: In a console which outputs lots of text quickly, it's very difficult to scroll up!
//I'm not sure if this is Mavericks-specific, but it's annoying and worth fixing.

- (BOOL)shouldScrollToBottom {
    NSRect visibleRect = [[self.enclosingScrollView contentView] documentVisibleRect];
    NSRect bounds = [[self.enclosingScrollView documentView] bounds];
    
    if (NSMaxY(visibleRect) >= NSMaxY(bounds)) {
        return true;
    } else {
        return false;
    }
}

@end




@implementation NSObject (main)

+ (void)load {
	ZKSwizzle(myNSTabView, NSTabView);
	ZKSwizzle(myNSTextFinderIndicatorManager, NSTextFinderIndicatorManager);
	ZKSwizzle(myNSMethodSignature, NSMethodSignature);
	ZKSwizzle(myNSMenu, NSMenu);
	ZKSwizzle(myEditor, Editor);
	ZKSwizzle(myNSAttributeDictionary, NSAttributeDictionary);
	ZKSwizzle(myNSUserDefaults, NSUserDefaults);
    
    ZKSwizzle(myProcessManager, ProcessManager);
    ZKSwizzle(myRunner, Runner);
    ZKSwizzle(myConsoleTextView, ConsoleTextView);
}

@end
