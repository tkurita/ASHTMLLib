#import "ASFormatting.h"
#import <Carbon/Carbon.h>
#import <OSAKit/OSAScript.h>

@implementation ASFormatting

+ (NSDictionary *)styleRunsForSource:(NSString *)source
{
	OSAScript *a_script = [[[OSAScript alloc] initWithSource:source] autorelease];
	NSDictionary *error_info;
	[a_script compileAndReturnError:&error_info];
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
		//NSLog([attributes description]);
		[attr_list addObject:attributes];
		[code_list addObject:[[styled_source attributedSubstringFromRange:effectiveRange] string]];
	}
	NSArray *font_names = [attr_list valueForKeyPath:@"NSFont.familyName"];
	NSArray *font_sizes = [attr_list valueForKeyPath:@"NSFont.pointSize"];
	NSArray *font_colors = [attr_list valueForKey:@"NSColor"];
	return [NSDictionary dictionaryWithObjectsAndKeys:font_names, @"font", 
									font_sizes, @"size", font_colors, @"color",code_list, @"code", nil];
}

+ (NSAppleEventDescriptor *)styleNames
{
	OSStatus			err = noErr;
	ComponentInstance	ci = 0 ;
	err = errOSAGeneralError ;
	NSString *err_msg = @"Fail to get style names.";
	
	if ( ( ci = OpenDefaultComponent ( kOSAComponentType, kAppleScriptSubtype ) ) == 0 )
	{
		err_msg = [NSString stringWithFormat:@"Fail to OpenDefaultComponent : %d", err];
		goto cleanup;
	}
	
	AEDescList aestyle_names;
	if ((err = ASGetSourceStyleNames(ci, kOSAModeNull, &aestyle_names)) != noErr) {
		err_msg = [NSString stringWithFormat:@"Fail to ASGetSourceStyleNames : %d", err];
		goto cleanup;
	}
	
	NSAppleEventDescriptor *names = [[NSAppleEventDescriptor alloc]initWithAEDescNoCopy:&aestyle_names];
	err = noErr;
	
cleanup:
	if ( ci != 0 ) {
		CloseComponent ( ci ) ;
		ci = 0 ;
	}
	
	if (err != noErr) {
		[NSException raise:@"ASFormattingException" format:err_msg];
	}
	return [names autorelease];
}

NSAppleEventDescriptor *parseStyle(const STElement * inStyle)
{
	Str255		fontName ;
	OSStatus	err ;
	NSString *err_msg;
	
	NSAppleEventDescriptor *style_record = [NSAppleEventDescriptor recordDescriptor];
	//font name
	if ( ( err = FMGetFontFamilyName (inStyle -> stFont, fontName ) ) != noErr ) {
		err_msg = [NSString stringWithFormat:@"Fail to FMGetFontFamilyName : %d", err];
		goto cleanup;
	}
	NSString *font_name = (NSString *)CFStringCreateWithPascalString(NULL, fontName, CFStringGetSystemEncoding());
	[style_record setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[font_name autorelease]]
					forKeyword:'fonO']; // font is not pFont in AppleScript Studio
	/*
	[style_record setParamDescriptor:[NSAppleEventDescriptor descriptorWithInt32:[font_name autorelease]]
					forKeyword:pFont];
	*/

	//font size
	[style_record setParamDescriptor:[NSAppleEventDescriptor descriptorWithInt32:inStyle->stSize]
					forKeyword:pSize];
	
	//color
	[style_record setParamDescriptor:
					[NSAppleEventDescriptor descriptorWithDescriptorType:typeRGBColor
											bytes:&inStyle->stColor length:sizeof(inStyle->stColor)]
					forKeyword:pColor];

	err = noErr;
	
cleanup:
	if (err != noErr) {
		[NSException raise:@"ASFormattingException" format:err_msg];
	}

	return style_record;
}

+ (NSAppleEventDescriptor *)styles
{
	OSStatus			err ;
	ComponentInstance	ci = 0 ;
	STHandle			sourceStyles = 0 ;
	err = errOSAGeneralError ;
	if ( ( ci = OpenDefaultComponent ( kOSAComponentType, kAppleScriptSubtype ) ) == 0 )
	{
		goto cleanup;
	}
	//	get AppleScript formats as a TextEdit style table
	if ( ( err = ASGetSourceStyles ( ci, & sourceStyles ) ) != noErr )
	{
		goto cleanup ;
	}

	//	sanity check: make sure the style table is non-null
	err = memFullErr ;
	if ( sourceStyles == 0 )
	{
		goto cleanup ;
	}

	//	sanity check: make sure the style table is big enough to
	//	contain all the AppleScript styles
	if ( GetHandleSize ( ( Handle ) sourceStyles ) < kASNumberOfSourceStyles * sizeof ( STElement ) )
	{
		goto cleanup ;
	}
	
	//	lock the style table
	HLock ( ( Handle ) sourceStyles ) ;
	
	NSAppleEventDescriptor *formats = [NSAppleEventDescriptor listDescriptor];
	for ( int styleIndex = kASSourceStyleUncompiledText ;
			  styleIndex < kASNumberOfSourceStyles;
			  styleIndex ++ )
	{
		[formats insertDescriptor:parseStyle((*sourceStyles) + styleIndex) atIndex:0];
	}

	//	clear result code
	err = noErr ;

cleanup :
	//	close the component connection
	if ( ci != 0 ) {
		CloseComponent ( ci ) ;
		ci = 0 ;
	}

	//	forget source styles
	if ( sourceStyles != 0 ) {
		DisposeHandle ( ( Handle ) sourceStyles ) ;
		sourceStyles = 0 ;
	}

	return formats;
}

@end
