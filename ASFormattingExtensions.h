#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface NSAppleEventDescriptor (ASFormattingExtensions)

+ (NSAppleEventDescriptor *)descriptorWithCGFloat:(CGFloat)aValue;
+ (NSAppleEventDescriptor *)descriptorWithColor:(NSColor *)aColor;

@end
