#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"




@interface myNSTabView : NSTabView
@end


@implementation myNSTabView

- (void)selectTabViewItem:(id)arg1 {
    ZKOrig(void, arg1);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabChanged" object:nil];
}

- (void)removeTabViewItem:(id)arg1 {
    ZKOrig(void, arg1);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabChanged" object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end




/* Fixes lots of crashes, such as when the user opens Preferences.
 
 I don't know why this works. I'm a simple guy. I look at the crash log, and the crash log says the app crashed because signatureWithObjCTypes's type signature was empty. So I made it so it can't be empty. And now the app doesn't crash. */

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




/* Fixes a problem which occurs when the user (1) saves and closes a FooLanguage file, (2) disables FooLanguage in CodeRunner Preferences, and (3) re-opens the FooLanguage file. */

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




@implementation NSObject (main)

+ (void)load {
    ZKSwizzle(myNSTabView, NSTabView);
    ZKSwizzle(myNSTextFinderIndicatorManager, NSTextFinderIndicatorManager);
    ZKSwizzle(myNSMethodSignature, NSMethodSignature);
    ZKSwizzle(myNSMenu, NSMenu);
}

@end
