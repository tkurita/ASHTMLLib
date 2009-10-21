#import "ASFormattingExtensions.h"
#import "NSAppleEventDescriptor+NDScriptData.h"

@implementation NSAppleEventDescriptor (ASFormattingExtensions)

+ (NSAppleEventDescriptor *)descriptorWithCGFloat:(CGFloat)aValue
{
#if CGFLOAT_IS_DOUBLE
	return [self descriptorWithDouble:aValue];
#else
	return [self descriptorWithFloat:aValue];
#endif
}

+ (NSAppleEventDescriptor *)descriptorWithColor:(NSColor *)aColor
{
	RGBColor qdColor;
	CGFloat red, green, blue, alpha;
	[aColor getRed:&red green:&green blue:&blue alpha:&alpha];
	qdColor.red = (unsigned short)(red * 65535.0f);
	qdColor.green = (unsigned short)(green * 65535.0f);
	qdColor.blue = (unsigned short)(blue * 65535.0f);
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeRGBColor 
														  bytes:&qdColor 
														 length:sizeof(RGBColor)];
}

@end
