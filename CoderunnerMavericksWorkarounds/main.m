#import <Foundation/Foundation.h>
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

@implementation NSObject (main)
+ (void)load {
    ZKSwizzle(myNSMethodSignature, NSMethodSignature);
}
@end
