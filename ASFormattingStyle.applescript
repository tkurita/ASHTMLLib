global XDict
global XList
global RGBColor
global CSSBuilder

property _style_names : {"uncompiled", "normal", "langKeyword", "appKeyword", "comment", "literal", "userDefine", "reference"}

on css_class(style_rec)
	my _styleDict's key_for_value(style_rec)
	return my _styleDict's key_for_value(style_rec)
end css_class

on as_css()
	set a_css to make CSSBuilder
	
	script SelectorAdder
		on do({a_name, format_rec})
			set a_rgb to RGBColor's make_with_decimal16(color of format_rec)
			a_css's add_selector("." & a_name, {{"font-family", font of format_rec}, {"color", a_rgb's as_htmlcolor()}})
		end do
	end script
	
	my _styleDict's each(SelectorAdder)
	return a_css
end as_css

on as_unicode()
	set a_css to as_css()
	return a_css's as_unicode()
end as_unicode

on build_css()
	set a_css to as_css()
	return a_css's as_unicode()
end build_css

on make_from_setting()
	set style_records to call method "styles" of class "ASFormatting"
	
	script FormattingStyle
		property _styleDict : XDict's make_with_lists(_style_names, style_records)
	end script
	return FormattingStyle
end make_from_setting

on make_from_plist()
	tell application "System Events"
		set applescript_plist to file "com.apple.applescript.plist" of preferences folder as alias
		set a_record to value of contents of property list file (applescript_plist as Unicode text)
	end tell
	set style_rec to XList's make_with(|AppleScriptTextStyles| of a_record)
	
	script StyleParser
		on do(a_text)
			set a_list to XList's make_with_text(a_text, ";")
			set a_rgb_list to XList's make_with_text(a_list's item_at(4), space)
			script TextToInteger
				on do(a_value)
					set contents of a_value to (a_value as integer)
					return true
				end do
			end script
			
			a_rgb_list's each(TextToInteger)
			
			return {font:a_list's item_at(1), size:((a_list's item_at(3)) as integer), color:a_rgb_list's list_ref()}
		end do
	end script
	
	set syle_rec_parsed to style_rec's map_as_list(StyleParser)
	
	script FormattingStyle
		property _styleDict : XDict's make_with_lists(_style_names, style_rec_parsed)
	end script
	
	return FormattingStyle
end make_from_plist

on run
	--set style_with_osax to AppleScript formatting
	set aobj to make_from_plist()
	aobj's build_css()
end run