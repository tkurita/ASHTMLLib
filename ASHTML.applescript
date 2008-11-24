global ASFormattingStyle
global HTMLElement
global XList
global XText
global XCharacterSet

property _brTag : "<br />"
property lineFeed : ASCII character 10
property _white_charset : missing value
property _temporary_doctitle : "** HTML Formatting **"

property _outputAsLIst : false
property _formattingStyle : missing value
property _wrapWithBlock : true
property _targetObj : missing value
property _target_text : missing value


on initialize()
	set my _formattingStyle to make_from_setting() of ASFormattingStyle
	set my _white_charset to XCharacterSet's make_whites_newlines()'s push("")
	set my _targetObj to missing value
	set my _target_text to missing value
end initialize

on formatting_style()
	return my _formattingStyle
end formatting_style

on temporary_doctitle()
	return _temporary_doctitle
end temporary_doctitle

on set_output_as_list(a_flag)
	set _outputAsLIst to a_flag
end set_output_as_list

on set_wrap_with_block(a_flag)
	set _wrapWithBlock to a_flag
end set_wrap_with_block

on logToConsole(a_text)
	do shell script "echo " & quoted form of a_text & ">/dev/console"
end logToConsole

on css_as_unicode()
	if _formattingStyle is missing value then
		set _formattingStyle to make_from_setting() of ASFormattingStyle
	end if
	return _formattingStyle's as_unicode()
end css_as_unicode

on markup_with_style(a_style, a_text)
	--log a_text
	local class_name
	set class_name to _formattingStyle's css_class(a_style)
	if _white_charset's is_member(a_text) then
		return a_text's as_unicode()
	end if
	
	if class_name is not missing value then
		set a_list to XList's make_with(get every paragraph of a_text)
		script StyleApplyer
			on do(a_line)
				if _white_charset's is_member(a_line) then
					return contents of a_line
				else
					set a_span to HTMLElement's make_with("span", {{"class", class_name}})
					a_span's push_content(contents of a_line)
					return a_span's as_html()
				end if
			end do
		end script
		
		set result_list to a_list's map(StyleApplyer)
		return result_list's as_unicode_with(lineFeed)
	else
		return a_text's as_unicode()
	end if
end markup_with_style

on escape_characters(a_text)
	set a_text to a_text's replace("&", "&amp;")
	set a_text to a_text's replace(">", "&gt;")
	set a_text to a_text's replace("<", "&lt;")
	set a_text to a_text's replace(quote, "&quot;")
	
	return a_text
end escape_characters

on process_paragraph(a_text)
	set nChar to count characters of a_text
	if nChar is 0 then
		return my _brTag
	end if
	
	set a_div to HTMLElement's make_with("div", {})
	if a_text starts with tab then
		set n to 1
		repeat with i from 1 to nChar
			if (character n of a_text is tab) then
				set n to n + 1
			else
				exit repeat
			end if
		end repeat
		set nTab to n - 1
		
		if nChar is nTab then
			return my _brTag
		else
			a_div's set_attribute("style", "text-indent:" & nTab * 4 & "ex;")
			set a_text to text n thru -1 of a_text
		end if
	end if
	
	a_div's push_content(a_text)
	return a_div
end process_paragraph

on target_text()
	if my _targetObj is not missing value then
		tell application "Script Editor"
			return contents of contents of my _targetObj
		end tell
	end if
	if _target_text is not missing value then
		return my _target_text
	end if
	return missing value
end target_text

on process_attribute_runs(content_list, font_list, size_list, color_list, prefer_inline)
	set content_list to XList's make_with(content_list)
	set font_list to XList's make_with(font_list)
	set size_list to XList's make_with(size_list)
	set color_list to XList's make_with(color_list)
	
	repeat while (content_list's count_items() > 0) -- remove empty lines in tail.
		if _white_charset's is_member(content_list's item_at(-1)) then
			repeat with a_container in {content_list, font_list, size_list, color_list}
				a_container's delete_at(-1)
			end repeat
		else
			exit repeat
		end if
	end repeat
	
	set n_attr to content_list's count_items()
	if n_attr is 0 then
		error "No contents in the document." number 1480
	end if
	
	set out_list to make XList
	set is_new_line to true
	repeat with i from 1 to n_attr
		--local a_text
		set a_text to XText's make_with(content_list's item_at(i))
		set a_text to my escape_characters(a_text)
		if (not is_new_line) and (length of a_text > 1) and (a_text's starts_with(lineFeed)) then
			set is_new_line to true
		end if
		
		set a_style to {font:font_list's item_at(i), size:size_list's item_at(i), color:color_list's item_at(i)}
		set text_list to make XList
		repeat with a_line in every paragraph of a_text
			--local indent_text
			set a_line to XText's make_with(a_line)
			if is_new_line then
				set {indent_text, a_line} to a_line's strip_beginning()
			else
				set indent_text to ""
			end if
			if color of a_style is not missing value then
				text_list's push(indent_text & markup_with_style(a_style, a_line))
			else
				text_list's push(indent_text & a_line's as_unicode())
			end if
			if not is_new_line then
				set is_new_line to true
			end if
		end repeat
		set taged_text to text_list's as_unicode_with(lineFeed)
		out_list's push(taged_text)
		set is_new_line to (taged_text ends with lineFeed)
	end repeat
	
	set out_text to out_list's as_unicode_with("")
	set source_list to XList's make_with(get every paragraph of out_text)
	set n_par to count source_list
	set is_inline to (prefer_inline and (n_par is 1))
	local out_html
	set out_html to make HTMLElement
	set wrapWithDiv to n_par > 1
	
	if (not is_inline) and (my _wrapWithBlock) then
		out_html's set_attribute("class", "sourceCode")
		if wrapWithDiv then
			set a_name to "div"
		else
			set a_name to "p"
		end if
		out_html's set_element_name(a_name)
	end if
	
	script ParProcessor
		on do(a_text)
			out_html's push_content(process_paragraph(contents of a_text))
			return true
		end do
	end script
	
	if wrapWithDiv then
		source_list's each(ParProcessor)
	else
		out_html's push_content(out_text)
	end if
	
	set out_contents to out_html's contents_ref()
	if out_contents's item_at(-1) is my _brTag then
		out_contents's delete_at(-1)
	end if
	
	return out_html
end process_attribute_runs

on process_file(a_path, prefer_inline)
	--log "start process_file"
	set style_runs to call method "styleRunsForFile:" of class "ASFormatting" with parameter a_path
	--log style_runs
	set my _target_text to |source| of style_runs
	--log "will end process_file"
	return process_attribute_runs(code of style_runs, |font| of style_runs, |size| of style_runs, |color| of style_runs, prefer_inline)
end process_file

on process_document(doc_ref)
	--log "start process_document"
	tell application "Script Editor"
		set runForSelection to ("" is not (contents of selection of doc_ref))
		
		if runForSelection then
			set _targetObj to a reference to selection of doc_ref
		else
			set _targetObj to doc_ref
		end if
		tell contents of contents of _targetObj
			set content_list to every attribute run
			set font_list to font of every attribute run
			set size_list to size of every attribute run
			set color_list to color of every attribute run
		end tell
	end tell
	--log "end process_document"
	return process_attribute_runs(content_list, font_list, size_list, color_list, runForSelection)
end process_document

on is_launched()
	tell application "System Events"
		set a_list to application processes whose name is "Script Editor"
	end tell
	return ((length of a_list) > 0)
end is_launched

on process_text(codeText, prefer_inline)
	set style_runs to call method "styleRunsForSource:" of class "ASFormatting" with parameter codeText
	return process_attribute_runs(code of style_runs, |font| of style_runs, |size| of style_runs, |color| of style_runs, prefer_inline)
end process_text

on process_text_with_editor(codeText)
	if _formattingStyle is missing value then
		set _formattingStyle to make_from_setting() of ASFormattingStyle
	end if
	set docTitle to _temporary_doctitle
	if is_launched() then
		tell application "Script Editor"
			if exists document docTitle then
				set contents of document docTitle to codeText
				check syntax document docTitle
			else
				make new document with properties {name:docTitle, contents:codeText}
			end if
		end tell
	else
		tell application "Script Editor"
			launch
			make new document with properties {name:docTitle, contents:codeText}
		end tell
	end if
	return process_document(document docTitle of application "Script Editor")
end process_text_with_editor

(*
on main()
	set _outputAsLIst to false
	set_wrap_with_block(false)
	set _formattingStyle to make_from_setting() of ASFormattingStyle
	set a_text to process_document(front document of application "Script Editor")
	--log a_text
	tell application (path to frontmost application as Unicode text)
		set the clipboard to (a_text)
	end tell
	--beep
end main
*)
on do_debug()
	--process_text("say_something(a_message)")
	initialize()
	set a_text to process_document(front document of application "Script Editor")
	--log a_text
end do_debug

(*
on run
	return debug()
	return main()
	try
		main()
	on error errMsg
		display dialog errMsg
	end try
end run

*)