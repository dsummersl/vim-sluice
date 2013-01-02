" New implementations:
" - data sources (that can pretty much stay as is.
"     - stateless
" - Signs: a wrapper around the gutter implementation (point to cache what is
"   currently there.
"     - state (tie to window)
" - MacroSigns: a wrapper around the gutter implementation that only paints on
"   the signs in the current viewpoint.
"     - state (tie to window)
" - Window: encapsulate the entire state of the current window (size,
"   location?)
"     - state (tie to window)
" - Painter (takes Signs or MacroSigns):
"     - stateless

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
	if &buftype == "help" || &buftype == "nofile" || &diff == 1 || &buftype == 'quickfix'
		" situations in which we don't want this: help files, nofiles, diff mode
		let anyEnabled = 0
	endif
	if anyEnabled == 1
		" finally, if we are enabled by any means...check to make sure that there
		" aren't any folds. We don't work with folds.
		exe "keepjumps 1"
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
    " TODO remove this - it unplaces everything in every window.
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
  " Generate data for each plugin (if its enabled), and combine it into one master list:
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
  " Generate the paint data"{{{
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
" Parameters: searchResults are of the form returned by CombineData.
" 
" Return: dictionary of lines that are currently set. Each line contains the
" standard elements created by CombineData. Additional possible keys:
" 
" 'visible'  - if the line is currently displayed on the screen then this would
"              be set to '1'.
" 'plugins'  - each plugin that paints on the line.
" 
" All data is cached in the buffer (b:cached_signs).
function! mvom#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)"{{{
	if !exists('b:cached_signs') | let b:cached_signs = {} | endif
	let results = {}
	" First collate all of the search results into one hash where the 'macro line'
  " number points to all matching search results.
  "
  " Additional keys added:
  " - plugins: all matching search results
  " - visible: if 1, then the results are currently visible in the window.
	for [line, data] in items(a:searchResults)
    "TODO If using icons, then we want the true offset, not the locinFile...
    " We need a better way of tracking what has been placed on the screen.
    "  - a dictionary that shows all the locations of the signs that we're
    "    managing.
		let locinInFile = mvom#util#location#ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
    let modulo = mvom#util#location#ConvertToModuloOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
		if !has_key(results,locinInFile)
			let results[locinInFile] = copy(data)
			let results[locinInFile]['visible'] = (line >= a:firstVisible && line <= a:lastVisible) ? 1:0
			let results[locinInFile]['plugins'] = []
		endif

    let modulo = float2nr(mvom#util#location#ConvertToModuloOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines) / 10.0)
    let data['modulo'] = modulo
    call add(results[locinInFile]['plugins'],data)
	endfor

  " For those lines that have more than one plugin match at this point,
  " we'll want to call the Reconcile method to get proper UI looks.
  " paint any new things:
	for [line, val] in items(results)
		if len(val['plugins']) > 1
			for datap in val['plugins']
        for p in datap['plugins']
          let render = mvom#renderers#util#FindRenderForPlugin(p)
          let plugin = mvom#renderers#util#FindPlugin(p)
          let results[line] = {render}#reconcile(plugin['options'],val)
        endfor
			endfor
		endif
	endfor

  " Setup highlighting and signs
	for [line,val] in items(results)

    " Ensure there are defaults.
		if !has_key(val,'text') | let val['text'] = '..' | endif
		if !has_key(val,'fg') | let val['fg'] = val['bg'] | endif

    " Create the fg/bg highlighting for non-icon signs
    exe "highlight! ".mvom#util#color#GetHighlightName(val)." guifg=#".val['fg']." guibg=#".val['bg']

    let fname = mvom#util#color#GetSignName(val)
    if !exists('g:mvom_sign_'. fname)
      call VULog( "let g:mvom_sign_". fname ."=1")
      exe "let g:mvom_sign_". fname ."=1"
      if exists('g:mvom_alpha') && g:mvom_alpha
        " TODO make a standard cache directory
        let image = mvom#renderers#icon#makeImage(10,10)
        call image.addRectangle(val['bg'],0,0,10,10)
        for pl in val['plugins']
          if has_key(pl,'iconcolor')
            call image.placeRectangle(pl['iconcolor'],pl['modulo'],pl['iconwidth'],1,pl['iconalign'])
          endif
        endfor
        call image.generatePNGFile(fname)
        let results[line]['icon'] = image['cachedir'] . fname .'.png'
        exe "sign define ". fname ." icon=". results[line]['icon'] ." text=".val['text']." texthl=".mvom#util#color#GetHighlightName(val)
      else
        exe "sign define ". fname ." text=".val['text']." texthl=".mvom#util#color#GetHighlightName(val)
      endif
    endif
    " did we paint this line previously?
    if has_key(b:cached_signs,line)
      " did we paint something different this time?
      if b:cached_signs[line] != val
        " if so, unpaint what we did before, and paint the new thing.
        call {a:unpaintFunction}(line,b:cached_signs[line])
        call {a:paintFunction}(line,val)
      endif
    else
      " something new, paint it.
      call {a:paintFunction}(line,val)
    endif
	endfor

  " Finally, is there anything old that doesn't exist anymore?
	for [line,val] in items(b:cached_signs)
    if !has_key(results,line)
      call {a:unpaintFunction}(line,b:cached_signs[line])
    endif
  endfor

	let b:cached_signs = results
	return results
endfunction"}}}

" vim: set fdm=marker:
