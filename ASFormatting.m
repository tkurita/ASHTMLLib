#import "ASFormatting.h"
#import <Carbon/Carbon.h>
#import <OSAKit/OSAScript.h>
#import "ASFormattingExtensions.h"

#define useLog 0

@implementation ASFormatting

+ (NSString *)scriptSource:(NSString *)path
{
	NSDictionary *error_info;
	NSAppleScript *a_script = [[NSAppleScript alloc] initWithContentsOfURL:
								[NSURL fileURLWithPath:path] error:&error_info];
	
	return [a_script source];
}

+ (NSDictionary *)styleRunsForOSAScript:(OSAScript *)aScript
{
	NSAttributedString *styled_source = [aScript richTextSource];
	if (!styled_source) {
		return nil;
	}
	NSMutableArray *attr_list = [NSMutableArray array];
	NSMutableArray *code_list = [NSMutableArray array];
 	NSDictionary *attributes;
	unsigned int length = [styled_source length];
	NSRange effectiveRange = NSMakeRange(0, 0);
	NSRange all_range = NSMakeRange(0, length);
	while (NSMaxRange(effectiveRange) < length) {
		attributes = [styled_source attributesAtIndex:NSMaxRange(effectiveRange) 
								longestEffectiveRange:&effectiveRange inRange:all_range];
		[attr_list addObject:attributes];
		[code_list addObject:[[styled_source attributedSubstringFromRange:effectiveRange] string]];
	}
	NSArray *font_names = [attr_list valueForKeyPath:@"NSFont.fontName"];
	NSArray *font_sizes = [attr_list valueForKeyPath:@"NSFont.pointSize"];
	NSArray *font_colors = [attr_list valueForKeyPath:@"NSColor.rgbArray"];
#if useLog
	NSLog([attr_list description]);
#endif
	return @{@"font": font_names, 
			@"size": font_sizes, @"color": font_colors,@"code": code_list, 
			@"source": [styled_source string]};
}

+ (NSDictionary *)styleRunsForFile:(NSString *)path
{
	NSDictionary *error_info = nil;
	NSURL *url = [NSURL fileURLWithPath:path];
	OSAScript *a_script = a_script= [[OSAScript alloc] initWithContentsOfURL:url 
																	   error:&error_info];
    if (error_info) {
        NSLog(@"Error in styleRunsForFile %@, path : %@", error_info, path);
        return nil;
    }
	return [self styleRunsForOSAScript:a_script];
}

+ (NSDictionary *)styleRunsForSource:(NSString *)source
{
	OSAScript *a_script = [[OSAScript alloc] initWithSource:source];
	NSDictionary *error_info = nil;
	[a_script compileAndReturnError:&error_info];
	if (error_info) {
		return error_info;
	}
	NSAttributedString *styled_source = [a_script richTextSource];
	
	NSMutableArray *attr_list = [NSMutableArray array];
	NSMutableArray *code_list = [NSMutableArray array];
 	NSDictionary *attributes;
	unsigned int length = [styled_source length];
	NSRange effectiveRange = NSMakeRange(0, 0);
	NSRange all_range = NSMakeRange(0, length);
	while (NSMaxRange(effectiveRange) < length) {
		attributes = [styled_source attributesAtIndex:NSMaxRange(effectiveRange) 
								longestEffectiveRange:&effectiveRange inRange:all_range];
		[attr_list addObject:attributes];
		[code_list addObject:[[styled_source attributedSubstringFromRange:effectiveRange] string]];
	}
	NSArray *font_names = [attr_list valueForKeyPath:@"NSFont.fontName"];
	NSArray *font_sizes = [attr_list valueForKeyPath:@"NSFont.pointSize"];
	NSArray *font_colors = [attr_list valueForKeyPath:@"NSColor.rgbArray"];
	return @{@"font": font_names, 
			@"size": font_sizes, @"color": font_colors,@"code": code_list};
}

+ (NSAppleEventDescriptor *)styleNames
{
	OSStatus			err = noErr;
	ComponentInstance	ci = 0 ;
	err = errOSAGeneralError ;
	
    if ((ci = [[OSALanguage languageForName:@"AppleScript"] componentInstance]) ==0 )
	{
        [NSException raise:@"ASFormattingException" format:@"%@",
                    @"Fail to obtain componentInstance in styleNames"];
		return nil;
	}
	
	AEDescList aestyle_names;
	if ((err = ASGetSourceStyleNames(ci, kOSAModeNull, &aestyle_names)) != noErr) {
        [NSException raise:@"ASFormattingException" format:@"Fail to ASGetSourceStyleNames : %d", err];
        return nil;

	}
	
	NSAppleEventDescriptor *names = [[NSAppleEventDescriptor alloc]initWithAEDescNoCopy:&aestyle_names];
	return names;
}

NSAppleEventDescriptor *parseStyle2(const NSDictionary *styleDict)
{
	NSAppleEventDescriptor *style_record = [NSAppleEventDescriptor recordDescriptor];
	//font name
	
	[style_record setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:
									  [styleDict[@"NSFont"] fontName]]
						  forKeyword:'fonO']; // font is not pFont in AppleScript Studio
	
	//font size
	[style_record setParamDescriptor: 
	 [NSAppleEventDescriptor descriptorWithCGFloat:
	  [styleDict[@"NSFont"] pointSize]]
						  forKeyword:pSize];
	
	//color
	[style_record setParamDescriptor:
	 [NSAppleEventDescriptor descriptorWithColor:styleDict[@"NSColor"]]
						  forKeyword:pColor];
	return style_record;
}

NSDictionary *parseStyle3(const NSDictionary *styleDict)
{
	NSString *font = [styleDict[@"NSFont"] fontName];
#if CGFLOAT_IS_DOUBLE
	NSNumber *size = @([styleDict[@"NSFont"] 
												 pointSize]);
#else
	NSNumber *size = [NSNumber numberWithFloat:[[styleDict objectForKey:@"NSFont"] 
												 pointSize]];
#endif
	/*
	CGFloat red, green, blue, alpha;
	[[styleDict objectForKey:@"NSColor"]
		getRed:&red green:&green blue:&blue alpha:&alpha];
	NSArray *rgb = [NSArray arrayWithObjects:
					[NSNumber numberWithUnsignedShort:(unsigned short)(red * 65535.0f)],
					[NSNumber numberWithUnsignedShort:(unsigned short)(green * 65535.0f)],
					[NSNumber numberWithUnsignedShort:(unsigned short)(blue * 65535.0f)], nil];
	 */
	NSArray *rgb = [styleDict[@"NSColor"] rgbArray];
	NSDictionary *result = @{@"font": font, @"size": size, @"color": rgb};
	return result;
}


+ (NSArray *)sourceAttributes
{
	OSStatus			err = noErr;
	ComponentInstance	ci = 0 ;
    if ((ci = [[OSALanguage languageForName:@"AppleScript"] componentInstance]) ==0 )
	{
        [NSException raise:@"ASFormattingException" format:
         @"Fail to obtain componentInstance in sourceAttributes"];
		return nil;
	}
	
	CFArrayRef source_styles = NULL;
	if ((err = ASCopySourceAttributes(ci, &source_styles)) != noErr) {
        [NSException raise:@"ASFormattingException" format:@"Fail to ASCopySourceAttributes : %d", err];
        return nil;
    }
    
	return (NSArray *)CFBridgingRelease(source_styles);
}

+ (NSAppleEventDescriptor *)styles2
{
	
	NSArray *source_styles = [self sourceAttributes];
	if (!source_styles) return nil;
	NSAppleEventDescriptor *formats = [NSAppleEventDescriptor listDescriptor];
	for ( int ind = 0; ind < [source_styles count]; ind ++ )
	{
		[formats insertDescriptor:parseStyle2(source_styles[ind]) 
						  atIndex:0];
	}
	return formats;
}

+ (NSArray *)styles3
{
	
	NSArray *source_styles = [self sourceAttributes];
	if (!source_styles) return nil;
	
	NSMutableArray *formats = [NSMutableArray arrayWithCapacity:[source_styles count]];
	
	for ( int ind = 0; ind < [source_styles count]; ind ++ )
	{
		[formats addObject:parseStyle3(source_styles[ind])];
	}
	return formats;
}

@end
