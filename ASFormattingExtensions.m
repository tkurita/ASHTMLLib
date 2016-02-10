#import "ASFormattingExtensions.h"


@implementation NSColor (ASFormattingExtensions)

- (NSArray *)rgbArray
{
	CGFloat red, green, blue, alpha;
	[self getRed:&red green:&green blue:&blue alpha:&alpha];
	NSArray *rgb = @[@((unsigned short)(red * 65535.0f)),
					@((unsigned short)(green * 65535.0f)),
					@((unsigned short)(blue * 65535.0f))];
	return rgb;
}

@end

@implementation NSAppleEventDescriptor (ASFormattingExtensions)

+ (NSAppleEventDescriptor *)descriptorWithCGFloat:(CGFloat)a_value
{
	descriptorWithDescriptorType:bytes:length:
#if CGFLOAT_IS_DOUBLE
	return [self descriptorWithDescriptorType:typeIEEE64BitFloatingPoint 
										 bytes:&a_value 
										length:sizeof(a_value)];
#else
	return [self descriptorWithDescriptorType:typeIEEE32BitFloatingPoint 
										bytes:&a_value
									   length:sizeof(a_value)];
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
