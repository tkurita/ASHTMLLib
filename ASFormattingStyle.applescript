global XDict
global XList
global RGBColor
global CSSBuilder

property _style_names : {"uncompiled", "normal", "langKeyword", "appKeyword", "comment", "literal", "userDefine", "reference"}

script StyleComparator
	property parent : AppleScript
	
	on is_similar_color(c1, c2)
		set cdiff to {(item 1 of c1) - (item 1 of c2), (item 2 of c1) - (item 2 of c2), (item 3 of c1) - (item 3 of c2)}
		set sq to (item 1 of cdiff) ^ 2 + (item 2 of cdiff) ^ 2 + (item 3 of cdiff) ^ 2
		return (sq < 4)
	end is_similar_color
	
	on do(v1, v2)
		-- log "start do of StyleComparator"
		set a_result to v1 is v2
		if a_result then return true
		if not (size of v1 is size of v1) then
			return false
		end if
		--log "end do of StyleComparator"
		return is_similar_color(color of v1, color of v2)
	end do
end script

on inline_stylesheet(style_rec)
	set a_rgb to RGBColor's make_with_decimal16(color of style_rec)
	return "font-family:" & (font of style_rec) & ";color:" & a_rgb's as_htmlcolor()
end inline_stylesheet

on css_class(style_rec)
	--log "start css_class"
	--log style_rec
	try
		set a_key to my _styleDict's key_for_value(style_rec)
	on error number 900
		set comparator_buff to my _styleDict's value_comparator()
		my _styleDict's set_value_comparator(StyleComparator)
		set a_key to my _styleDict's key_for_value(style_rec)
		my _styleDict's set_value_comparator(comparator_buff)
	end try
	--log a_key
	--log "end css_class"
	return a_key
end css_class

on as_css()
	--log "start as_css"
	set a_css to make CSSBuilder
	
	script SelectorAdder
		on do({a_name, format_rec})
			set a_rgb to RGBColor's make_with_decimal16(color of format_rec)
			a_css's add_selector("." & a_name, {{"font-family", font of format_rec}, {"color", a_rgb's as_htmlcolor()}})
			return true
		end do
	end script
	
	my _styleDict's each(SelectorAdder)
	--log "end as_css"
	return a_css
end as_css

on as_unicode()
	return build_css()
end as_unicode

on build_css()
	--log "start build_css"
	set a_css to as_css()
	set a_result to a_css's as_unicode()
	--log "end build css"
	return a_result
end build_css

on make_from_setting()
	--log "start make_from_setting in ASFormattingStyle"
	tell current application's class "ASFormatting"
		set style_records to its styles3() as list
	end tell
	repeat with a_rec in style_records
		set contents of a_rec to {font:|font| of a_rec, size:|size| of a_rec, color:|color| of a_rec}
	end repeat
	tell current application's class "NSUserDefaults"'s standardUserDefaults()
		set style_names to its arrayForKey_("CSSClassNames") as list
	end tell
	if length of style_records < length of style_names then
		set style_names to items 1 thru (length of style_records) of style_names
	end if
	repeat with n from 1 to length of style_names
		set a_name to item n of style_names as text
		if a_name is "" then
			set item n of style_names to "AppleScriptFormattingStyle" & (n as Unicode text)
		else
			set item n of style_names to a_name
		end if
	end repeat
	if length of style_records > length of style_names then
		repeat with n from (length of style_names) + 1 to (length of style_records)
			set end of style_names to "AppleScriptFormattingStyle" & (n as Unicode text)
		end repeat
	end if
	script FormattingStyle
		property _styleDict : XDict's make_with_lists(style_names, style_records)
	end script
	return FormattingStyle
end make_from_setting

on make_from_plist() -- deprecated. use make_from_setting.
	tell application id "com.apple.systemevents"
		set applescript_plist to file "com.apple.applescript.plist" of preferences folder as alias
		set a_record to value of contents of property list file (applescript_plist as Unicode text)
	end tell
	set style_rec to XList's make_with(|AppleScriptTextStyles| of a_record)
	
	script StyleParser
		on do(a_text)
			set a_list to XList's make_with_text(a_text, ";")
			set a_rgb_list to XList's make_with_text(a_list's item_at(4), space)
			script TextToInteger
				on do(a_value, sender)
					set contents of a_value to (a_value as integer)
					return true
				end do
			end script
			
			a_rgb_list's enumerate(TextToInteger)
			
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
