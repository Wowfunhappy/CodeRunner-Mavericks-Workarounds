#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ZKSwizzle.h"




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




@interface myNSFindIndicatorOverlayView : NSView
@end


@implementation myNSFindIndicatorOverlayView

- (void)drawRect:(struct CGRect)arg1 {
    //Do nothing. Workaround for bug which occurs when searching for text and switching tabs.
}

@end




@interface myNSMenu : NSMenu
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
    ZKSwizzle(myNSMethodSignature, NSMethodSignature);
    ZKSwizzle(myNSFindIndicatorOverlayView, _NSFindIndicatorOverlayView);
    ZKSwizzle(myNSMenu, NSMenu);
}
@end
