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
    //Do nothing. Avoids bug when switching tabs while text is highlighted.
}

@end




@implementation NSObject (main)
+ (void)load {
    ZKSwizzle(myNSMethodSignature, NSMethodSignature);
    ZKSwizzle(myNSFindIndicatorOverlayView, _NSFindIndicatorOverlayView);
}
@end
