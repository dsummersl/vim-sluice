
function! mvom#renderer#RePaintMatches()"{{{
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
		let w:cached_dim['data'] = mvom#renderer#CombineData(g:mv_plugins)
		call mvom#renderer#PaintMV(w:cached_dim['data'])
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
	let data = mvom#renderer#CombineData(g:mv_plugins)
	if firstVisible != w:cached_dim['top'] || lastVisible != w:cached_dim['bottom'] || winHeight != w:cached_dim['height'] || cursorPos != w:cached_dim['pos'] || &hls != w:cached_dim['hls'] || data != w:cached_dim['data']
		call mvom#renderer#PaintMV(data)
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
endfunction"}}}

" Add a specific plugin and rendering.
"
" Parameters:
"     pluginName the path to the plugin file (ie, mvom/plugins/underscore
"                would be mvom#plugins#underscore).
"     options    Options for the plugin. Depends on the plugin, but all
"                plugins have the following options:
"
"                    render Path to the renderer type.
"
function! mvom#renderer#add(pluginName,options)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	let old_enabled=g:mvom_enabled
	let g:mvom_enabled=0
	call {a:pluginName}#init(a:options)
	call add(g:mv_plugins,{ 'plugin': a:pluginName, 'options': a:options })
	let g:mvom_enabled=old_enabled
endfunction

" Remove a plugin.
function! mvom#renderer#remove(pluginName)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	let old_enabled=g:mvom_enabled
	let g:mvom_enabled=0
	call {a:pluginName}#deinit()
  let cnt = -1
  for p in g:mv_plugins
    let cnt = cnt + 1
    if p['plugin'] == a:pluginName
      break
    endif
  endfor
  if cnt >= 0
    call remove(g:mv_plugins,cnt)
  endif
	let g:mvom_enabled=old_enabled
endfunction

" Returns a string description suitable for embedding in one's
" statusline.
"
" For instance, if 'search and underline' are configure then it would display:
"
"     '\:und' -- undercursor
"     '/:s//' -- search
"     '+:git' -- git changes
"     '+:svn' -- subversion changes
"     '+: hg' -- mercurial changes
"     '+:bzr' -- bazaare changes
"     '#:chg' -- frequent changes 
"     '#:ind' -- # indents
function! mvom#renderer#statusline()
endfunction

" paint the matches for real, on the screen. With signs.
function! mvom#renderer#PaintMV(data)"{{{
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
		call mvom#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,a:data,"mvom#renderer#UnpaintSign","mvom#renderer#PaintSign")
		let w:mvom_lastcalldisabled = 0
	else
		let w:mvom_lastcalldisabled = 1
		sign unplace *
	endif
endfunction"}}}

function! mvom#renderer#CombineData(plugins)"{{{
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
		let render = pluginInstance['options']['render']
		let plugin = pluginInstance['plugin']
		let pluginData = {}
		for line in keys(allData)
			if count(allData[line]['plugins'],plugin) > 0
				let pluginData[line] = allData[line]
			endif
		endfor
		let paintData = {render}#paint(pluginInstance['options'],pluginData)
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
endfunction"}}}

function! mvom#renderer#PaintSign(line,dict)"{{{
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
endfunction"}}}

function! mvom#renderer#UnpaintSign(line,dict)
	exe "sign unplace ".a:line." buffer=".winbufnr(0)
endfunction

function! mvom#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)"{{{
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
				let plugin = mvom#renderers#util#FindPlugin(datap)
				let results[line] = {render}#reconcile(plugin['options'],val)
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
endfunction"}}}

" vim: set fdm=marker:
