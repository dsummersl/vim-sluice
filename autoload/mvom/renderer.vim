
function! mvom#renderer#RePaintMatches()"{{{
	let painted = 0
	if !exists('g:mvom_loaded') || g:mvom_loaded==0 || !exists('g:mvom_enabled') || g:mvom_enabled==0
		return painted
	endif
	let w:save_cursor = winsaveview()
	let w:save_registers = mvom#util#location#SaveRegisters()
  let current_dims = mvom#util#location#getwindowdimensions(mvom#renderer#CombineData(g:mv_plugins))
	" if there are no cached_dim then this is the first call to the
	" repaintfunction. Make the cache and paint.
	if !exists('w:cached_dim')
		let w:cached_dim = current_dims
		call mvom#renderer#PaintMV(w:cached_dim['data'])
		" TODO possible optimization: don't restore the view if it hasn't changed?
		call winrestview(w:save_cursor)
		" TODO ditto for load registers?
		call mvom#util#location#LoadRegisters(w:save_registers)
		return 1
	endif
  " TODO major bad thing here. If the file hasn't changed, and none of the
  " plugins need updates then...don't do anything!
  "if current_dims['data'] != w:cached_dim['data']
  "  " echom "current data ". string(current_dims['data']) ." != ". string(w:cached_dim['data'])
  "  echom "current data different "
  "endif
	if current_dims['top'] != w:cached_dim['top'] ||
        \current_dims['bottom'] != w:cached_dim['bottom'] ||
        \current_dims['height'] != w:cached_dim['height'] ||
        \&hls != w:cached_dim['hls'] ||
        \current_dims['data'] != w:cached_dim['data']
		call mvom#renderer#PaintMV(current_dims['data'])
		let painted = 1
	endif
	let w:cached_dim = current_dims
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

" Set a plugin option. See the related plugin documentation
" for what options are available.
function! mvom#renderer#setOption(pluginName,option,value)
  let options = mvom#renderers#util#FindPlugin(a:pluginName)['options']
  let options[a:option] = a:value
endfunction

" paint the matches for real, on the screen. With signs.
function! mvom#renderer#PaintMV(data)"{{{
	if !exists('g:mv_plugins') | return | endif
	let totalLines = line('$')
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	let anyEnabled = 0
	for pluginInstance in g:mv_plugins
		let plugin = pluginInstance['plugin']
		let options = pluginInstance['plugin']['options']
		if {plugin}#enabled(options)
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

" Given all the plugins, generate the line level data: which plugins have
" matches on which lines. Format is:
" {
" 	'<linenumber>': {
"     'count'     : number of matches on the line
"     'plugins'   : an array with the name of the 'Data' plugins that have matches on this particular line.
"     'line'      : line number
"     'text'      : text to display in signs area
"     'fg'        : foreground
"     'bg'        : background
"     'iconcolor' : gui color
"     'iconalign' : how to align the icon
"     'iconwidth' : how wide to paint the icon
" 		TODO linehi - hilighting for the linelevel option.
" 	}
" }
function! mvom#renderer#CombineData(plugins)"{{{
	"echo "START"
	let allData = {}
  " Generate data for each plugin, and combine it into one master list:
	for pluginInstance in a:plugins"{{{
		let plugin = pluginInstance['plugin']
		let options = pluginInstance['options']
		if !{plugin}#enabled(options)
			continue
		endif
		call winrestview(w:save_cursor) " so the plugins all get to start from the same 'window'
		let data={plugin}#data(options)
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
	endfor"}}}
	let resultData = {}
  " Render all the data"{{{
	for pluginInstance in a:plugins " now render everything
		let render = pluginInstance['options']['render']
		let plugin = pluginInstance['plugin']
		let pluginData = {}
    " Make a list of the lines that actually have plugin data present:
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
      for key in ["text","fg","bg","iconcolor","iconwidth","iconalign"]
        if has_key(paintData[line],key)
          let resultData[line][key] = paintData[line][key]
          let pluginData[line][key] = paintData[line][key]
        endif
      endfor
		endfor
	endfor"}}}
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

" Actual logic that paints the matches. Painting and searching are abstracted
" out so that it can be tested by itself.
" 
" Parameters: searchResults are of the form defined by CombineData.
" 
" Return: dictionary of lines that are currently set. Each line contains the
" standard elements created by CombineData. Additional possible keys:
" 
" 'visible'  - if the line is currently displayed on the screen then this would
"              be set to '1'.
" 'metaline' - when in 'meta' mode this is the line that represents the %
"              offset of the actual line.
" 
" Also makes some global variables for all the hilighting options that have
" possibly been created (so that they don't have to be recreated). These are
" created before the paintFunction is called, so that the paintFunction
" doesn't actually have to create any hilighting itself.
function! mvom#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)"{{{
	if !exists('b:cached_signs') | let b:cached_signs = {} | endif
	let results = {}
	" First colate all of hte search results into the 'macro' line (so several
	" lines will be condensed to one line:
  " TODO this should now be 'modulo' aware so that we don't condense multiple
  " matches if the icon support can handle it. I guess...just don't do it if
  " icons are supported.
  "
  " Additinoal keys added:
  " - count
  " - plugins
  " - visible
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
	for [line,val] in items(results)
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
					" gray). Or ansi-128?
					exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
				else
					" hack for the window plugin
					exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
				endif
			else
				exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']
			endif
      let modulo = mvom#util#location#ConvertToModuloOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
      let val['modulo'] = modulo
      let fname = mvom#util#color#GetSignName(val)
      if !exists('g:mvom_hi_'. fname)
        exe "let g:mvom_hi_". fname ."=1"
        if has_key(val,"iconwidth")
          let image = mvom#renderers#icon#makeImage()
          call image.addRectangle(val['bg'],0,0,50,50)
          call image.placeRectangle(val['iconcolor'],float2nr(modulo/2.0),val['iconwidth'],4,val['iconalign'])
          call image.generatePNGFile(fname)
          exe "sign define ". fname ." icon=/Users/danesummers/.vim/mvom-cache/". fname .".png text=".val['text']." texthl=".mvom#util#color#GetHighlightName(val)
        else
          exe "sign define ". fname ." text=".val['text']." texthl=".mvom#util#color#GetHighlightName(val)
        endif
      endif
		endif
		call {a:paintFunction}(line,val)
	endfor
	let b:cached_signs = results
	return results
endfunction"}}}

" vim: set fdm=marker:
