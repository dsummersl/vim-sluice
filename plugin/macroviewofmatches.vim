" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" ie, MarkSearch("Something","green", "*")
"function! MarkSearch(search,color="auto",character='*')
"endfunction
"function! MarkClearAll()
"endfunction
"
" TODO add a plugin that shows you the other matches if they are off screen.
" TODO I might want to not show search/undercursor/etc if they are onscreen
" (less clutter).
" TODO git plugin for additions and subtractions
" TODO a gundo compatible plugin - it shows you where you've been making
" changes (colors boldly the recent changes).

" mappings"{{{

" Sanity checks
if has( "signs" ) == 0 || has("float") == 0 || v:version/100 < 7
	echohl ErrorMsg
	echo "MacroViewOfMatches requires Vim to have +signs and +float support and Vim v7+"
	echohl None
	finish
endif

au! CursorHold * nested call RePaintMatches()
function! RePaintMatches()
	let painted = 0
	if !exists('g:mvom_loaded') || g:mvom_loaded==0 || !exists('g:mvom_enabled') || g:mvom_enabled==0
		return painted
	endif
	let w:save_cursor = winsaveview()
	let w:save_registers = mvom#util#location#SaveRegisters()
	" if there are no cached_dim then this is the first call to the
	" repaintfunction. Make the cache and paint.
	if !exists('w:cached_dim')
		let w:cached_dim = {}
		let w:cached_dim['top'] = line('w0')
		let w:cached_dim['bottom'] = line('w$')
		let w:cached_dim['height'] = winheight(0)
		let w:cached_dim['pos'] = line('.')
		let w:cached_dim['hls'] = &hls
		let w:cached_dim['data'] = CombineData(g:mv_plugins)
		call PaintMV(w:cached_dim['data'])
		" TODO possible optimization: don't restore the view if it hasn't changed?
		call winrestview(w:save_cursor)
		" TODO ditto for load registers?
		call mvom#util#location#LoadRegisters(w:save_registers)
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
	call mvom#util#location#LoadRegisters(w:save_registers)
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

" }}}
" Rendering Logic {{{
function! MVOM_Setup(pluginName,renderType)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	let old_enabled=g:mvom_enabled
	let g:mvom_enabled=0
	let a:pluginpath="mvom#plugins#".a:pluginName
	let a:renderpath="mvom#renderers#".a:renderType
	call {a:pluginpath}#init()
	call add(g:mv_plugins,{ 'plugin': a:pluginpath, 'render': a:renderpath })
	let g:mvom_enabled=old_enabled
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
		if {plugin}#enabled()
			let anyEnabled = 1
			break
		endif
	endfor
	if &buftype == "help" || &buftype == "nofile" || &diff == 1
		" situations in which we don't want this: help files, nofiles, diff mode
		let anyEnabled = 0
	endif
	if anyEnabled == 1
		" finally, if we are enabled by any means...check to make sure that there
		" aren't any folds. We don't work with folds.
		1
		exe "silent normal! zj"
		if line('.') != 1
			let anyEnabled = 0
		endif
		call winrestview(w:save_cursor)
	endif
	if anyEnabled
		call DoPaintMatches(totalLines,firstVisible,lastVisible,a:data,"UnpaintSign","PaintSign")
		let w:mvom_lastcalldisabled = 0
	else
		let w:mvom_lastcalldisabled = 1
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
		if !{plugin}#enabled()
			continue
		endif
		call winrestview(w:save_cursor) " so the plugins all get to start from the same 'window'
		let data={plugin}#data()
		for line in keys(data) " loop through all the data and add it to my own master list.
			"echo "plg ". plugin ." line ". line
			if has_key(allData,line)
				"echo "have entry: ". plugin
				"echo data
				"echo allData
				if count(allData[line]['plugins'],plugin) == 0
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
			if count(allData[line]['plugins'],plugin) > 0
				let pluginData[line] = allData[line]
			endif
		endfor
		let paintData = {render}#Paint(pluginData)
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
		let thesign=mvom#util#color#GetSignName(a:dict)
		"echom "sign place ".a:line." name=".thesign." line=".a:line." buffer=".winbufnr(0)
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
	" First colate all of hte search results into the 'macro' line (so several
	" lines will be condensed to one line:
	for [line, trash] in items(a:searchResults)
		"echo "doing ". line ." which is ". string( trash['plugins'] )
		let locinInFile = mvom#util#location#ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
		if has_key(results,locinInFile) && has_key(results[locinInFile],'count')
			" we already have a rendering for this line, add up the counts, and Reconcile for all the plugins involved.
			"echo "pluginsa: ". string( results[locinInFile]['plugins'] )
			"echo "pluginsb: ". string( trash['plugins'] )
			" we need to combine the 'plugins' so that they all get listed in together.
			let theplugs = mvom#util#color#Uniq(extend(results[locinInFile]['plugins'],a:searchResults[line]['plugins']))
			call extend(results[locinInFile],a:searchResults[line])
			let oldcount = results[locinInFile]['count'] 
			let results[locinInFile]['count'] = oldcount + a:searchResults[line]['count']
			let results[locinInFile]['plugins'] = theplugs
		else
			let results[locinInFile] = copy(trash)
			"echo "plugins: ". string( results[locinInFile]['plugins'] )
			let results[locinInFile]['visible'] = (line >= a:firstVisible && line <= a:lastVisible) ? 1:0
		endif
	endfor
	for [line, val] in items(results)
		" for those lines that have more than one plugin match at this point,
		" we'll want to call the Reconcile method to get proper UI looks.
		" paint any new things:
		if len(val['plugins']) > 1
			for datap in val['plugins']
				let render = mvom#renderers#util#FindRenderForPlugin(datap)
				let results[line] = {render}#Reconcile(val)
			endfor
		endif
	endfor
	sign unplace *
	for [key,val] in items(results)
		"echo "val = ". string(val)
		if !has_key(val,'text')
			let val['text'] = '..'
		endif
		if !has_key(val,'fg')
			let val['fg'] = val['bg']
		endif
		if has_key(val,'fg')
			if count(val['plugins'],"Window") > 0
				if len(val['plugins']) == 1
					" hack for the window plugin
					" TODO NR-16 ctermcolor support. Thisi s jsut NR8 (we could use dark
					" gray)
					exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
				else
					" hack for the window plugin
					exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
				endif
			else
				exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
			endif
			exe "let g:mvom_hi_".mvom#util#color#GetHighlightName(val)."=1"
			exe "sign define ".mvom#util#color#GetSignName(val)." text=".val['text']." texthl=".mvom#util#color#GetHighlightName(val)
		endif
		call {a:paintFunction}(key,val)
	endfor
	let b:cached_signs = results
	return results
endfunction
"}}}
" Private Variables "{{{
if !exists('w:mvom_lastcalldisabled') | let w:mvom_lastcalldisabled=1 | endif
"}}}
" Default Configuration"{{{
" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=100

" Maximum number of forward and backward searches to performed
if !exists('g:mvom_max_searches ') | let g:mvom_max_searches = 75 | endif

" default background color of the gutter:
if !exists('g:mvom_default_bg') | let g:mvom_default_bg = 'dddddd' | endif
exe "autocmd BufNewFile,BufRead * highlight! SignColumn guifg=white guibg=#". g:mvom_default_bg

" Slash options:
if !exists('g:mvom_slash_chars ') | let g:mvom_slash_chars ='/ ' | endif
if !exists('g:mvom_slash_color ') | let g:mvom_slash_color ='0055ff' | endif

" Ex options (when Slash/Backslash overlap):
if !exists('g:mvom_ex_chars ') | let g:mvom_ex_chars ='X ' | endif
if !exists('g:mvom_ex_color ') | let g:mvom_ex_color ='0055ff' | endif

" Backslash options:
if !exists('g:mvom_backslash_chars ') | let g:mvom_backslash_chars ='\ ' | endif
if !exists('g:mvom_backslash_color ') | let g:mvom_backslash_color ='00ff00' | endif

" UnderCursor options:
" TODO ideally I'd read the hl-IncSearch colors (but I don't know quite how...)
if !exists('g:mvom_undercursor_bg ') | let g:mvom_undercursor_bg ='e5f1ff' | endif
if !exists('g:mvom_undercursor_fg ') | let g:mvom_undercursor_fg ='000000' | endif

" Background options:
" showinline will show both the highlight both the areas that correspond to
" the current visible window, but also make the area where the cursor is
" slightly darker:
if !exists('g:mvom_bg_showinline') | let g:mvom_bg_showinline=1 | endif

" Configuration:
if !exists('g:mvom_enabled') | let g:mvom_enabled=1 | endif
if !exists('g:mvom_loaded')
	" Setup the type of plugins you want:
	" Show the last search with //
	call MVOM_Setup('search','slash')
	" Show all keywords in the file that match whats under your cursor with \\
	"call MVOM_Setup('undercursor','backslash')
	" Show the visible portion with a darker background
	call MVOM_Setup('window','background')
	let g:mvom_loaded = 1
endif
"}}}
" vim: set fdm=marker noet:
