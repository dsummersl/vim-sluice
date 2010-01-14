" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" mappings"{{{
" TODO I'd like to support the general concept of 'there are X matches in this
" row ... by making the intensity progressively darker (5 levels thank you
" human recog).
"
" TODO the folding logic messes things up - have to somehow take into account
" the folded lines or the 'green' and -- parts get all messed up.
" au VimResized * call PaintMatches(@/). Problem is it looks like signs aren't
" supported over the folded regions??
"
" LAYOUT:
"
" UI layer: has macro and non macro mode? No this is kinda up to the renderer.
" You'd have a renderer for macro and a renderer for non macro -- you tell the
" plugin which mode you want (macro/non) and it swaps between them easily
" enough I guess? I can't really display both can I? well...I could use one
" column for macro and one for micro...Yes I like that. Then I'd use slightly
" different color schemes for them. Chocolate-ish for the macro on far left.
"
" CODE:
"
" You can specify (currently) up to two different kinds of data that you'd
" like to display. The data source just lists the dictionary and the renderer
" type. Renderer types:
"
" '/' renderer (up to two kinds) and overlap
" color - background color modulation
" color - foreground color modulation?
" blinky - something that could blink intermittently on the top of the other
" renderings?
"
" A renderer is given ALL data

au! CursorHold * nested call RePaintMatches()
function! RePaintMatches()
	let painted = 0
	let w:save_cursor = winsaveview()
	if !exists('w:cached_dim')
		let w:cached_dim = {}
		let w:cached_dim['top'] = line('w0')
		let w:cached_dim['bottom'] = line('w$')
		let w:cached_dim['height'] = winheight(0)
		let w:cached_dim['pos'] = line('.')
		let w:cached_dim['hls'] = &hls
		let w:cached_dim['data'] = CombineData(g:mv_plugins)
		call PaintMV(w:cached_dim['data'])
		" TODO restore first line as the 'top' line
		call winrestview(w:save_cursor)
		return 1
	endif
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	let winHeight = winheight(0)
	let cursorPos = line('.')
	let data = CombineData(g:mv_plugins)
	if firstVisible != w:cached_dim['top'] || lastVisible != w:cached_dim['bottom'] || winHeight != w:cached_dim['height'] || cursorPos != w:cached_dim['pos'] || &hls != w:cached_dim['hls'] || data != w:cached_dim['data']
		call PaintMV(data)
		let painted = 1
	endif
	let w:cached_dim['top'] = line('w0')
	let w:cached_dim['bottom'] = line('w$')
	let w:cached_dim['height'] = winheight(0)
	let w:cached_dim['pos'] = line('.')
	let w:cached_dim['hls'] = &hls
	let w:cached_dim['data'] = data
	call winrestview(w:save_cursor)
	return painted
endfunction
"}}}
" Builtin data sources {{{
" The basic idea for this is that there are X plugins supported and each
" plugin is expected to have specific function names:
"
" <plugin>Init() -- called the first time its used
" <plugin>Enabled() -- called on repaints... 1 for true, 0 for false.
" <plugin>#Data(): return data. 
" Each data uses a 'num'(row number) as key and then the following:
" {
" 	'count': number of occurrances on this line
" }
" Note: you can move the cursor around as much as you want as the position has
" been saved and will be restored after this method call.

" Search"{{{
function! SearchInit()
endfunction
function! SearchData()
	let results = {}
	let n = 1
	1
	let searchResults = {}
	" TODO I should do 'c' option as well, but it requires some cursor moving
	" to ensure no infinite loops
	while search(@/,"We") > 0
		let here = line('.')
		let cnt = 0
		if has_key(results,here) && has_key(results[here],'count')
			let cnt = results[here]['count']
		else
			let results[here] = {}
		endif
		let cnt = cnt + 1
		let results[here]['count'] = cnt
		let n = n+1
	endwhile
	return results
endfunction
function! SearchEnabled()
	return &hls == 1
endfunction
"}}}
" Window (show current visible window in macro area)"{{{
function! WindowInit()
endfunction
function! WindowData()
	let firstVisible = line("w0")
	let lastVisible = line("w$")
	let totalLines = line("$")
	let currentLine = line(".")
	let n = firstVisible
	let results = {}
	let offsetOfCursor = ConvertToPercentOffset(currentLine,firstVisible,lastVisible,totalLines)
	while n <= lastVisible
		let results[n] = {}
		let results[n]['count'] = 1
		if offsetOfCursor == ConvertToPercentOffset(n,firstVisible,lastVisible,totalLines) 
			let results[n]['iscurrentline'] = 1
		endif
		let n = n+1
	endwhile
	return results
endfunction
function! WindowEnabled()
	return &hls == 1
endfunction
"}}}
" UnderCursor: show matches for the 'word' the cursor is currently on"{{{
function! UnderCursorInit()
	exe "highlight! UnderCursor guifg=#9966ff guibg=#".g:mvom_default_bg
endfunction
function! UnderCursorData()
	let old_search=@/
	exe "silent normal *"
	let results=SearchData()
  execute 'silent syntax clear UnderCursor'
	execute 'syntax match UnderCursor "'. @/ .'" containedin=ALL'
	" remove the current line, b/c obviously we know about that
	if has_key(results,w:save_cursor['lnum'])
		call remove(results,w:save_cursor['lnum'])
	endif
	let @/=old_search
	return results
endfunction
function! UnderCursorEnabled()
	if &hls == 0
		execute 'silent syntax clear UnderCursor'
	endif
	return &hls == 1
endfunction
"}}}
" }}}
" Builtin rendering types {{{
" The rendering types are pluggable. Here is the expected format for them:
" <render>Init() -- init anything it needs to init.
" <render>PaintMacro() -- return a dictionary telling what symbols to place
" in macro mode.
" Should have the following keys for each line:
" {
"   'text':  -- 2 symbols to display if there is a match
"   'fg': -- foreground
"   'bg': -- background
"   'linehi': -- highlight for the group. Probably not meaningful for macro mode...
" }
" <render>Paint(vals) -- return a dictionary telling what symbols to place
" in micro mode.
" vals param has the following keys:
" {
" 	'count': --- number of ... whatever... matches, links, etc
" 	'line': --- line of concern
" }
" Should have the following keys:
" {
"   'text':  -- (optional) 2 symbols to display if there is a match
"   'fg': -- foreground
"   'bg': -- background
"   'linehi': -- highlight for the group
" }
"

" Slash (//) painter"{{{
function! SlashInit()
endfunction
function! SlashPaint(vals)
	let matchColor = 'ffff00'
	let result = {}
	for line in keys(a:vals)
		let result[line] = { 'text': '//', 'fg': matchColor, 'bg':g:mvom_default_bg }
	endfor
	return result
endfunction
function! SlashReconcile(vals,key)
	let matchColor = 'ffff00'
	let result = {}
	for line in keys(a:vals)
		let result[line] = { 'text': 'XX', 'fg': matchColor, 'bg':g:mvom_default_bg }
	endfor
	return result
endfunction
"}}}
" Backslash (\\) painter"{{{
function! BackslashInit()
	" same as slash
	call SlashInit()
endfunction
function! BackslashPaint(vals)
	let matchColor = '9966ff'
	let result = {}
	for line in keys(a:vals)
		let result[line] = { 'text': '\\', 'fg': matchColor, 'bg':g:mvom_default_bg }
	endfor
	return result
endfunction
function! BackslashReconcile(vals,state)
	" same as slash
	call SlashReconcile(a:vals,a:state)
endfunction
""}}}
" Background Painter"{{{
function! BGInit()
endfunction
function! BGPaint(vals)
	let result = {}
	let bgcolor = g:mvom_default_bg
	let modded = RGBToHSV(HexToRGB(bgcolor))
	" TODO if the bg is dark this code doesn't really color correclty (needs to
	" change by more and by something fixed I think
	if modded[2] > 50 " if its really light, lets darken, otherwise we'll lighten
		let modded[2] = float2nr(modded[2]*0.9)
	else
		let modded[2] = float2nr(modded[2]+modded[2]*0.1)
	endif
	let bgcolor = RGBToHex(HSVToRGB(modded))
	for line in keys(a:vals)
		let color = bgcolor
		if has_key(a:vals[line],'iscurrentline')
			let darkened = RGBToHSV(HexToRGB(bgcolor))
			let darkened[2] = float2nr(darkened[2]*0.9)
			let color = RGBToHex(HSVToRGB(darkened))
		endif
		if has_key(a:vals[line],'text')
			let result[line] = { 'bg':color }
		else
			let result[line] = { 'bg':color }
		endif
	endfor
	return result
endfunction
function! BGReconcile(vals)
	let result = {}
	for line in keys(a:vals)
		let result[line] = { 'bg':'00ff00' }
	endfor
	return result
endfunction
"}}}
" }}}
" Rendering Logic {{{
function! SetupMV(pluginName,renderType)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	call {a:pluginName}Init()
	call add(g:mv_plugins,{ 'plugin': a:pluginName, 'render': a:renderType })
endfunction

" paint the matches for real, on the screen. With signs.
function! PaintMV(data)
	if !exists('g:mv_plugins') | return | endif
	"TODO add in some cacheing? IE: if you call this method should it always
	"repaint everything, or should it only do it if dimensions have changed
	"and locations have changed. For now. The simpler.

	let totalLines = line('$')
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	let anyEnabled = 0
	for pluginInstance in g:mv_plugins
		let plugin = pluginInstance['plugin']
		if {plugin}Enabled()
			let anyEnabled = 1
			break
		endif
	endfor
	if anyEnabled
		call DoPaintMatches(totalLines,firstVisible,lastVisible,a:data,"UnpaintSign","PaintSign")
	else
		sign unplace *
	endif
endfunction

" Given all the plugins, generate the line level data: which plugins have
" matches on which lines. Format is:
" {
" 	'<linenumber>': {
" 		'count': number of matches on the line
" 		'plugins': an array with the name of the 'Data' plugins that have
" 		matches on this particular line.
" 		'line': line number
" 		'text': text to display in signs area
	"   'fg': foreground
	"   'bg': background
" 		TODO linehi - hilighting for the linelevel option.
" 	}
" }
function! CombineData(plugins)
	"echo "START"
	let allData = {}
	for pluginInstance in a:plugins
		let plugin = pluginInstance['plugin']
		if !{plugin}Enabled()
			continue
		endif
		call winrestview(w:save_cursor) " so the plugins all get to start from the same 'window'
		let data={plugin}Data()
		for line in keys(data) " loop through all the data and add it to my own master list.
			"echo "plg ". plugin ." line ". line
			if has_key(allData,line)
				"echo "have entry: ". plugin
				"echo data
				"echo allData
				if index(allData[line]['plugins'],plugin) == -1 
					"echo "and its not listed"
					" do we have the current plugin already? If not:
					let oldcount = allData[line]['count']
					let oldcount = oldcount + data[line]['count']
					call extend(allData[line],data[line])
					let allData[line]['count'] = oldcount
					call add(allData[line]['plugins'],plugin)
				end
			else
				let allData[line] = {}
				"echo "new entry: ". plugin
				"echo data
				"echo allData
				call extend(allData[line],data[line])
				let allData[line] = data[line] " count variable
				let allData[line]['line'] = line+0
				let allData[line]['plugins'] = [plugin]
			endif
		endfor
	endfor
	let resultData = {}
	for pluginInstance in a:plugins " now render everything
		let render = pluginInstance['render']
		let plugin = pluginInstance['plugin']
		let pluginData = {}
		for line in keys(allData)
			if index(allData[line]['plugins'],plugin) >= 0
				let pluginData[line] = allData[line]
			endif
		endfor
		let paintData = {render}Paint(pluginData)
		for line in keys(paintData)
			"echo "looking at line ".line." plugin ".plugin
			"echo allData
			"echo pluginData
			"echo paintData
			if has_key(resultData,line)
				let resultData[line] = extend(resultData[line],allData[line])
			else
				let resultData[line] = copy(allData[line])
			endif
			if has_key(paintData[line],'text')
				let resultData[line]['text'] = paintData[line]['text']
				let pluginData[line]['text'] = paintData[line]['text']
			endif
			if has_key(paintData[line],'fg')
				let resultData[line]['fg'] = paintData[line]['fg']
				let pluginData[line]['fg'] = paintData[line]['fg']
			endif
			let resultData[line]['bg'] = paintData[line]['bg']
			let pluginData[line]['bg'] = paintData[line]['bg']
		endfor
	endfor
	return resultData
endfunction

function! PaintSign(line,dict)
	" echom "here is ". here ." and firstVisible = ". firstVisible ." and lastVisible = ". lastVisible ." gonna do ". locinInFile
	" echom "fg with ". hiType
	if has_key(a:dict,'fg')
		let thesign=<SID>GetSignName(a:dict)
		"echo "sign place ".a:line." name=".thesign." line=".a:line." buffer=".winbufnr(0)
		exe "sign place ".a:line." name=".thesign." line=".a:line." buffer=".winbufnr(0)
	else
		" if 'visible' then this is a non-matching line that's currently
		" 'visible'.
	endif
endfunction

function! UnpaintSign(line,dict)
	exe "sign unplace ".a:line." buffer=".winbufnr(0)
endfunction

" Actual logic that paints the matches. painting and searching are abstracted
" out so that I can test this by itself.
" Parameters: searchResults are of the form defined by CombineData.
" Return: dictionary of lines that are currently set. Each line contains the
" standard elements created by CombineData. Additional possible keys:
" 'visible' - if the line is currently displayed on the screen then this would
" be set to '1'.
" 'metaline' - when in 'meta' mode this is the line that represents the %
" offset of the actual line.
"
" Also makes some global variables for all the hilighting options that have
" possibly been created (so that they don't have to be recreated). These are
" created BEFORE the paintFunction is called, so that the paintFunction
" doesn't actually have to create any hilighting itself.
function! DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)
	if !exists('b:cached_signs') | let b:cached_signs = {} | endif
	let results = {}
	for [line, trash] in items(a:searchResults)
		let locinInFile = ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
		if has_key(results,locinInFile) && has_key(results[locinInFile],'count')
			" we already have a rendering for this line, add up the counts, and Reconcile for all the plugins involved.
			call extend(results[locinInFile],a:searchResults[line])
			let oldcount = results[locinInFile]['count'] 
			let results[locinInFile]['count'] = oldcount + a:searchResults[line]['count']
		else
			let results[locinInFile] = copy(a:searchResults[line])
			let results[locinInFile]['visible'] = (line >= a:firstVisible && line <= a:lastVisible) ? 1:0
		endif
	endfor
	" TODO for those lines that have more than one plugin match at this point,
	" we'll want to call the Reconcile method to get proper UI looks.
	" paint any new things:
	sign unplace *
	for [key,val] in items(results)
		if !has_key(val,'text')
			let val['text'] = '..'
		endif
		if !has_key(val,'fg')
			let val['fg'] = val['bg']
		endif
		if has_key(val,'fg')
			"exe "highlight! VisWin ctermfg=black ctermbg=green guifg=".val['fg']." guibg=".val['bg']
			exe "highlight! ".<SID>GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
			exe "let g:mvom_hi_".<SID>GetHighlightName(val)."=1"
			exe "sign define ".<SID>GetSignName(val)." text=".val['text']." texthl=".<SID>GetHighlightName(val)
		endif
		call {a:paintFunction}(key,val)
	endfor
	let b:cached_signs = results
	return results
endfunction
"}}}
" Utility functions"{{{
function! <SID>GetHighlightName(dictionary)
	return "MVOM_".a:dictionary['fg'].a:dictionary['bg']
endfunction

function! <SID>GetSignName(dictionary)
	return <SID>GetHighlightName(a:dictionary)."_".<SID>GetHumanReadables(a:dictionary['text'])
endfunction

function! <SID>GetHumanReadables(chars)
	let result = ""
	let n = 0
	while n < len(a:chars)
		if a:chars[n] == '/'
			let result = result . 'fs'
		elseif a:chars[n] == '\'
			let result = result . 'bs'
		elseif a:chars[n] == '.'
			let result = result . 'dt'
		elseif a:chars[n] == '#'
			let result = result . 'hsh'
		elseif a:chars[n] == '-'
			let result = result . 'da'
		else
			let result = result . a:chars[n]
		end
		let n = n + 1
	endwhile
	return result
endfunction

" This function takes in some line number that is <= the total
" possible lines, and places it somewhere on the range between
" [start,end] depending on what percent of the match it is.
function! ConvertToPercentOffset(line,start,end,total)
	let percent = a:line / str2float(a:total)
	let lines = a:end - a:start
	return float2nr(percent * lines)+a:start
endfunction

" Convert a 6 character hex RGB to a 3 part (0-255) array.
function! HexToRGB(hex)
	return ["0x".a:hex[0:1]+0,"0x".a:hex[2:3]+0,"0x".a:hex[4:5]+0]
endfunction

" Convert a 3 part (0-255) array to a 6 char hex equivalent.
function! RGBToHex(hex)
	return printf("%02x%02x%02x",a:hex[0],a:hex[1],a:hex[2])
endfunction

" Make an array of HSV values from an array to RGB values.
function! RGBToHSV(rgb)
	let two55 = trunc(255)
	let normd = copy(a:rgb)
	let normd[0] = a:rgb[0]/two55
	let normd[1] = a:rgb[1]/two55
	let normd[2] = a:rgb[2]/two55
	let mx = max(a:rgb)/two55
	let mn = min(a:rgb)/two55
	let hue = 0
	if mx == mn
		let hue = 0
	elseif normd[0] == mx
		let hue = float2nr(60*((normd[1]-normd[2])/trunc(mx-mn))+360) % 360
	elseif normd[1] == mx
		let hue = float2nr(60*((normd[2]-normd[0])/trunc(mx-mn)))+120
	elseif normd[2] == mx
		let hue = float2nr(60*((normd[0]-normd[1])/trunc(mx-mn)))+240
	endif
	let sat = 0
	if mx > 0
		if mn == mx
			let sat = 0
		else
			let sat = 1-mn/trunc(mx)
		endif
	endif
	let val = mx
	return [float2nr(hue),float2nr(sat*100),float2nr(val*100)]
endfunction

function! HSVToRGB(hsv)
	let one00 = trunc(100)
	let normd = copy(a:hsv)
	let normd[0] = a:hsv[0]
	let normd[1] = a:hsv[1]/one00
	let normd[2] = a:hsv[2]/one00
	let six0 = trunc(60)
	let hi = float2nr(floor(normd[0]/six0)) % 6
	let f = normd[0]/six0 - floor(normd[0]/six0)
	let p = normd[2]*(1-normd[1])
	let q = normd[2]*(1-f*normd[1])
	let t = normd[2]*(1-(1-f)*normd[1])
	let result = [0,0,0]
	if hi == 0
		let result = [normd[2],t,p]
	elseif hi == 1
		let result = [q,normd[2],p]
	elseif hi == 2
		let result = [p,normd[2],t]
	elseif hi == 3
		let result = [p,q,normd[2]]
	elseif hi == 4
		let result = [t,p,normd[2]]
	elseif hi == 5
		let result = [v,p,q]
	endif
	let result[0] = float2nr(result[0]*255)
	let result[1] = float2nr(result[1]*255)
	let result[2] = float2nr(result[2]*255)
	return result
endfunction

""}}}
" test functions {{{

function! TestHexToRGBAndBack()
	call VUAssertEquals(HexToRGB("000000"),[0,0,0])
	call VUAssertEquals(HexToRGB("ffffff"),[255,255,255])
	call VUAssertEquals(HexToRGB("AAAAAA"),[170,170,170])
	call VUAssertEquals(RGBToHex([0,0,0]),"000000")
	call VUAssertEquals(RGBToHex([255,255,255]),"FFFFFF")
	call VUAssertEquals(RGBToHex([32,15,180]),"200FB4")
endfunction

function! TestRGBToHSVAndBack()
	call VUAssertEquals(RGBToHSV([0,0,0]),[0,0,0])
	call VUAssertEquals(RGBToHSV([255,255,255]),[0,0,100])
	call VUAssertEquals(RGBToHSV([255,0,0]),[0,100,100])
	call VUAssertEquals(RGBToHSV([0,255,0]),[120,100,100])
	call VUAssertEquals(RGBToHSV([0,0,255]),[240,100,100])
	call VUAssertEquals(RGBToHSV([50,50,50]),[0,0,19])
	call VUAssertEquals(RGBToHSV([100,100,100]),[0,0,39])

	call VUAssertEquals(HSVToRGB([0,0,0]),[0,0,0])
	call VUAssertEquals(HSVToRGB([100,100,100]),[84,255,0])
	call VUAssertEquals(HSVToRGB([0,100,100]),[255,0,0])
	call VUAssertEquals(HSVToRGB([120,100,100]),[0,255,0])
	call VUAssertEquals(HSVToRGB([240,100,100]),[0,0,255])
endfunction

function! Test1Data()
	return {}
endfunction
function! Test2Data()
	return {'1':{'count':1}}
endfunction
function! Test3Data()
	return {'1':{'count':1},'2':{'count':2}}
endfunction
function! Test4Data()
	return {'1':{'count':1,'isvis':1},'2':{'count':2}}
endfunction
function! Test5Data()
	return {'5':{'count':1},'6':{'count':2}}
endfunction
function! Test1Paint(data)
	return {}
endfunction
function! Test2Paint(data)
	return {'1':{'text':'..', 'fg':'testhi', 'bg':'testbg'}}
endfunction
function! Test3Paint(data)
	let results = {}
	for line in keys(a:data)
		let results[line] = copy(a:data[line])
		let results[line]['fg'] = 'testhi'
		let results[line]['bg'] = 'testbg'
	endfor
	return results
endfunction

function! TestCombineData()
  " put your curser in this block somewhere and then type ":call VUAutoRun()"
	" TODO these are still NOT passing.
	let w:save_cursor = winsaveview()
	call VUAssertEquals(CombineData([{'plugin':'Test1','render':'Test1'}]),{})
	call VUAssertEquals(CombineData([{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(CombineData([{'plugin':'Test1','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(CombineData([{'plugin':'Test2','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	" expect line 1 to have count=2 and then a line 2 of count 2
	" but then just the rendering for test2 will happen so...same old thing
	" there.
	call VUAssertEquals(CombineData([{'plugin':'Test3','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test3','Test2'], 'line':1, 'bg':'testbg'}})
	" if one data source has an extra key it should always be in the results
	" regardless of order:
	call VUAssertEquals(CombineData([{'plugin':'Test4','render':'Test2'},{'plugin':'Test3','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test4','Test3'], 'line':1, 'bg':'testbg', 'isvis':1}})
	call VUAssertEquals(CombineData([{'plugin':'Test3','render':'Test2'},{'plugin':'Test4','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test3','Test4'], 'line':1, 'bg':'testbg', 'isvis':1}})
	" non intersecting data sets, both should be there.
	call VUAssertEquals(CombineData([{'plugin':'Test4','render':'Test3'},{'plugin':'Test5','render':'Test3'}]), { '1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test4'], 'line':1, 'bg':'testbg', 'isvis':1}, '2':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test4'], 'line':2, 'bg':'testbg'}, '5':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test5'], 'line':5, 'bg':'testbg'}, '6':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test5'], 'line':6, 'bg':'testbg'}, })
endfunction

function! TestConvertToPercentOffset()
  " put your curser in this block somwhere and then type ":call VUAutoRun()"
  call VUAssertEquals(ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(ConvertToPercentOffset(50,70,100,100),85)
endfunction

function! TestGetHumanReadables()
	call VUAssertEquals(<SID>GetHumanReadables(""),"")
	call VUAssertEquals(<SID>GetHumanReadables("aa"),"aa")
	call VUAssertEquals(<SID>GetHumanReadables(".."),"dtdt")
	call VUAssertEquals(<SID>GetHumanReadables("\\\\"),"bsbs")
	call VUAssertEquals(<SID>GetHumanReadables("//"),"fsfs")
	call VUAssertEquals(<SID>GetHumanReadables("--"),"dada")
endfunction

function! TestGetSignName()
	call VUAssertEquals(<SID>GetSignName({'fg':'000000','bg':'111111','text':'--'}),"MVOM_000000111111_dada")
endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line)
endfunction

function! TestDoPaintMatches()
	call VUAssertEquals(DoPaintMatches(5,1,5,{},"UnpaintTestStub","PaintTestStub"),{})
	" if all lines are currently visible, don't do anything:
	" first just paint one line. We expect that the line '1' would be painted,
	" and that the highlight group is created (and 'Test1' is called).
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(DoPaintMatches(6,1,5,{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" two lines, implies some reconciliation should be happening here:
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(DoPaintMatches(10,1,5,{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000'},2:{'count':1,'plugins':['Test1'],'line':2,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':2,'plugins':['Test1'],'line':2,'text':'RR','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	"unlet! g:mvom_hi_MVOM_000000000000
	"call VUAssertEquals(DoPaintMatches(10,6,10,{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000'},10:{'count':1,'plugins':['Test1'],'line':10,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{6:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':0},10:{'count':1,'plugins':['Test1'],'line':10,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	"call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" dubgging call
	" echo DoPaintMatches(line('$'),line('w0'),line('w$'),CombineData(g:mv_plugins),"UnpaintTestSign","PaintTestStub")
endfunction

function! TestSuite()
"call VURunnerRunTest('TestSuite')
	call TestCombineData()
	call TestConvertToPercentOffset()
	call TestDoPaintMatches()
	call TestGetHumanReadables()
	call TestGetSignName()
	call TestRGBToHSVAndBack()
	call TestHexToRGBAndBack()
endfunction
"}}}
" Startup and configuration"{{{

if has( "signs" ) == 0
	echohl ErrorMsg
	echo "MacroViewOfMatches requires Vim to have +signs support."
	echohl None
	finish
endif

" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=100

let g:mvom_default_bg='bbbbbb'
exe "hi! SignColumn term=standout ctermfg=1 ctermbg=7 guifg=DarkBlue guibg=#". g:mvom_default_bg

" Configuration:
call SetupMV('Search','Slash')
call SetupMV('UnderCursor','Backslash')
call SetupMV('Window','BG')

" "}}}
" vim: set fdm=marker:
