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
 
 I don't know why this works. I'm a simple guy. I look at the crash log, and the crash log says the app
 crashed because signatureWithObjCTypes's type signature was empty. So I made it so it can't be empty.
 And now the app doesn't crash. */

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
    ZKOrig(void, charRange);
    [[self textStorage] addAttribute:NSBackgroundColorAttributeName
                               value:[NSColor colorWithCalibratedWhite:0.5 alpha:0.25]
                               range:charRange];
    
    NSValue *rangeValue = [NSValue valueWithRange:charRange];
    objc_setAssociatedObject(self, @selector(lastMatchHighlight), rangeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSelectedRanges:(id)arg1 affinity:(unsigned long long)arg2 stillSelecting:(BOOL)arg3{
    ZKOrig(void, arg1, arg2, arg3);
    NSRange lastMatchHighlight = [objc_getAssociatedObject(self, @selector(lastMatchHighlight)) rangeValue];
    [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:lastMatchHighlight];
}

//Also not a bug, but CodeRunner overrides OS X's default `look up in dictionary` functionality to search documentation.
//Let's make it not do that.
- (void)quickLookWithEvent:(id)arg1 {
    [super quickLookWithEvent:arg1];
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




@interface myConsoleTextView : NSTextView
@end


@implementation myConsoleTextView

//Fixes: In a console which outputs lots of text quickly, it's very difficult to scroll up!
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




@interface myProcess : NSObject
@end


@implementation myProcess

- (void)startProcessWithExecutablePath:(id)arg1 args:(id)arg2 env:(id)arg3 width:(int)arg4 height:(int)arg5 encoding:(unsigned long long)arg6 {
    NSLog(@"(void)startProcessWithExecutablePath:(id)%@ args:(id)%@ env:(id)%@ width:(int)%d height:(int)%d encoding:(unsigned long long)%llu", arg1, arg2, arg3, arg4, arg5, arg6);
    ZKOrig(void, arg1, arg2, arg3, arg4, arg5, arg6);
    
    /*NSTask *task = [[NSTask alloc] init];
     
     // Setting launch path to 1st parameter 'arg1'
     task.launchPath = arg1;
     
     // Setting arguments to 2nd parameter 'arg2'
     task.arguments = arg2;
     
     // Setting environment to 3rd parameter 'arg3'
     task.environment = arg3;
     
     @try {
     [task launch];
     } // Catches and logs if there happens to be any errors
     @catch (NSException *exception) {
     NSLog(@"Failed to start task: %@", [exception description]);
     }*/
    
    
}

- (void)waitForExitStatus {
    NSLog(@"(void)waitForExitStatus");
    
    //    int fileDescriptor = ZKHookIvar(self, int, "fileDescriptor");
    //    close(fileDescriptor);
    
    ZKOrig(void);
}

- (void)readWriteError {
    NSLog(@"(void)readWriteError");
    ZKOrig(void);
}

- (void)read {
    //NSLog(@"(void)read");
    ZKOrig(void);
}

- (void)write {
    //NSLog(@"(void)write");
    ZKOrig(void);
}

- (int)getFileDescriptor {
    return ZKHookIvar(self, int, "fileDescriptor");
}

@end




@interface myProcessManager : NSObject
{
    BOOL shouldTerminate; //this is bad, deal with later.
}
@end

@implementation myProcessManager

-(void)mainLoop {
    //self->shouldTerminate = NO;
    
    while (true /*!self->shouldTerminate*/) {
        for (myProcess *process in [self getProcesses]) {
            [process read];
            if ([process shouldWrite]) {
                [process write];
            }
        }
        [NSThread sleepForTimeInterval:0.01];
        
        /*[[self getLock] lock];
        
        for (myProcess *process in [self getProcesses]) {
            int fd = [process getFileDescriptor];
            if (fd < 0) {
                [self removeProcess:process];
                NSLog(@"process removed!");
            } else {
                [process read];
                if ([process shouldWrite]) {
                    [process write];
                }
            }
        }
        [[self getLock] unlock];*/
    }
}

- (void)shouldTerminateLoop {
    self->shouldTerminate = YES;
}

- (NSRecursiveLock*)getLock {
    return ZKHookIvar(self, NSRecursiveLock *, "lock");
}

- (NSMutableArray*)getProcesses {
    return ZKHookIvar(self, NSMutableArray *, "processes");
}

- (void)addProcess:(id)arg1 {
    NSLog(@"(void)addProcess:(id)%@", arg1);
    ZKOrig(void, arg1);
}

- (void)removeProcess:(id)arg1 {
    NSLog(@"(void)removeProcess:(id)%@", arg1);
    ZKOrig(void, arg1);
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

- (void)stopRunningWithStatus:(int)arg1 {
    NSLog(@"(void)stopRunningWithStatus:(int)%d", arg1);
    ZKOrig(void, arg1);
}

@end




@interface myNSThread : NSThread
@end


@implementation myNSThread

+ (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)argument {
    NSLog(@"void)detachNewThreadSelector:(SEL)selector toTarget:(id)%@ withObject:(id)%@", target, argument);
    ZKOrig(void, selector, target, argument);
    /*static int calls = 0;
    if (calls < 3) {
        ZKOrig(void, selector, target, argument);
        calls++;
    }*/
}

- (void)start {
    NSLog(@"start");
    ZKOrig(void);
}

- (void)main {
    NSLog(@"main");
    ZKOrig(void);
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
    ZKSwizzle(myConsoleTextView, ConsoleTextView);
    
    ZKSwizzle(myProcess, Process);
    ZKSwizzle(myProcessManager, ProcessManager);
    ZKSwizzle(myRunner, Runner);
    ZKSwizzle(myNSThread, NSThread);
}

@end
