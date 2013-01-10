function! mvom#renderer#RePaintMatches()"{{{
	let painted = 0
	if !mvom#renderer#getenabled()
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

" Configuration and enable/disable functions {{{
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

" Set the status of the MVOM plugin in the current buffer.
" Sends a warning if the plugin is currently disabled.
function! mvom#renderer#setenabled(enable)
  let b:mvom_enabled = a:enable
  if mvom#renderer#getenabled()
    " TODO the undercursor plugin still highlights things when its disabled.
    " Make sure that all the plugin deinit methods get called.
    call mvom#renderer#RePaintMatches()
  else
		sign unplace *
  endif
endfunction

" Get the status of the MVOM plugin in the current buffer.
function! mvom#renderer#getenabled()
  if !exists('g:mvom_enabled')
    return 0
  endif
  if !g:mvom_enabled
    return 0
  endif
  if !exists('b:mvom_enabled')
    let b:mvom_enabled = g:mvom_default_enabled
  endif
  return b:mvom_enabled
endfunction

" }}}

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
" 	  'plugin name': {
"       'text'      : text to display in signs area
"       'fg'        : foreground
"       'bg'        : background
"       'iconcolor' : gui color
"       'iconalign' : how to align the icon
"       'iconwidth' : how wide to paint the icon
" 	    TODO linehi - hilighting for the linelevel option.
" 	  }
" 	}
" }
function! mvom#renderer#CombineData(plugins)"{{{
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
			if has_key(allData,line)
        let allData[line][plugin] = data[line]
				let allData[line]['count'] = allData[line]['count'] + 1
			else
        " do we have the current plugin already? If not:
				let allData[line] = {}
				let allData[line]['count'] = 1
				let allData[line][plugin] = data[line]
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
			if has_key(allData[line],plugin) > 0
				let pluginData[line] = allData[line][plugin]
			endif
		endfor
		let paintData = {render}#paint(pluginInstance['options'],pluginData)
    " once painted, store the results.
		for line in keys(paintData)
			if !has_key(resultData,line)
				let resultData[line] = {}
			endif
      let resultData[line][plugin] = copy(allData[line][plugin])
      for value in keys(paintData[line])
        let resultData[line][plugin][value] = paintData[line][value]
      endfor
		endfor
	endfor"}}}
	return resultData
endfunction"}}}

function! mvom#renderer#PaintSign(line,dict)"{{{
	if has_key(a:dict,'fg')
		let thesign=a:dict['hash']
    exe printf("sign place %s name=%s line=%s buffer=%s",a:line,a:dict['hash'],a:line,winbufnr(0))
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
function! mvom#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)"{{{
	if !exists('b:cached_signs') | let b:cached_signs = {} | endif
	let results = {}

  " Remove any previously painted signs
	for [line,val] in items(b:cached_signs)
    call {a:unpaintFunction}(line,b:cached_signs[line])
  endfor

  " compute the current 'height' of the window. that would be used by an
  " icon so that a line can be accurately rendered (TODO if the height is big it
  " should really 'fall' into the next line).
  let pixelsperline = float2nr(10 / (a:totalLines / (1.0*(a:lastVisible - a:firstVisible + 1))))
  let gutterImage = mvom#renderers#icon#makeImage(10,10*a:totalLines)

	" First collate all of the search results into one hash where the 'macro line'
  " number points to all matching search results.
  "
  " Additional keys added:
  " - plugins: all matching search results
  " - visible: if 1, then the results are currently visible in the window.
	for [line, data] in items(a:searchResults)
		let locinInFile = mvom#util#location#ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
    let modulo = float2nr(mvom#util#location#ConvertToModuloOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines) / 10.0)

		if !has_key(results,locinInFile)
			let results[locinInFile] = {}
			let results[locinInFile]['plugins'] = []
		endif

    " if the line is within the visible range, set it so:
    let results[locinInFile]['visible'] = (line >= a:firstVisible && line <= a:lastVisible) ? 1:0

    " setup the top level data values that are ultimately used for the signs
    " (the combination of all the plugins).
    call VULog("data = ". string(data))
    for plugin in keys(data)
      call add(results[locinInFile]['plugins'],data[plugin])
      let offset = len(results[locinInFile]['plugins'])-1
      for key in keys(data[plugin])
        let results[locinInFile][key] = data[plugin][key]
      endfor
      let results[locinInFile]['plugins'][offset]['plugin'] = plugin
      let results[locinInFile]['plugins'][offset]['modulo'] = modulo
      unlet plugin
    endfor
	endfor

  " For those lines that have more than one plugin match at this point,
  " we'll want to call the Reconcile method to get proper UI looks.
  " paint any new things:
	for [line, val] in items(results)
		if len(val['plugins']) > 1
      " for each plugin that overlaps, call reconcile. First come first serve
      " for overlapping key values.
			for p in val['plugins']
        let render = mvom#renderers#util#FindRenderForPlugin(p['plugin'])
        let plugin = mvom#renderers#util#FindPlugin(p['plugin'])
        " TODO the slash reconcile plugins need to know what other plugins it
        " is clashing with, otherwise they cannot figure out what sign to use
        " (clashing with background means nothing. Only clashing with another
        " slash is important).
        let reconciled = {render}#reconcile(plugin['options'],p)
        for key in keys(reconciled)
          let results[line][key] = reconciled[key]
        endfor
      endfor
      " make sure that any other options are also included, if they weren't
      " in any of the reconcile lists.
			for p in val['plugins']
        for key in keys(p)
          if !has_key(results[line],key)
            let results[line][key] = p[key]
          endif
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

    call gutterImage.addRectangle(val['bg'],0,10*(line-1),10,10)
    for pl in (val['plugins'])
      if has_key(pl,'iconcolor')
        " TODO provide a generic key 'iconfunction' that allows plugins
        " to provide their own custom icons. Move this into the 'slash'
        " definition. --- and work in the window backgrounds into the icon.
        "
        " TODO fix combine data so each plugin has its own data.
        " Place the actual plugin's mark:
        call gutterImage.placeRectangle(pl['iconcolor'],
              \pl['modulo']+10*(line-1),pl['iconwidth'],
              \pixelsperline,pl['iconalign'])
      endif
    endfor
  endfor

  " after the gutterimage is completely painted, define any missing
  " icon/signs, and then paint.
	for [line,val] in items(results)
    let fname = gutterImage.generateHash(0,10*(line-1),10,10)
    let results[line]['hash'] = fname
    if !exists('g:mvom_sign_'. fname)
      call VULog( "let g:mvom_sign_". fname ."=1")
      exe "let g:mvom_sign_". fname ."=1"
      if exists('g:mvom_alpha') && g:mvom_alpha
        " if an icon doesn't exist yet, generate it.
        if !filereadable(g:mvom_icon_cache . fname .'.png')
          " place the background color
          " DEBUG print the whole gutter. One long strip: :)
          "call gutterImage.generatePNGFile(g:mvom_icon_cache . 'gutter')
          call gutterImage.generatePNGFile(g:mvom_icon_cache . fname,0,10*(line-1),10,10)
        endif
        let results[line]['icon'] = g:mvom_icon_cache . fname .'.png'
        exe printf("sign define %s icon=%s text=%s texthl=%s",fname,results[line]['icon'],val['text'],mvom#util#color#GetHighlightName(val))
      else
        exe printf("sign define %s text=%s texthl=%s",fname,val['text'],mvom#util#color#GetHighlightName(val))
      endif
    endif
    " did we paint this line previously?
    call {a:unpaintFunction}(line,val)
    call {a:paintFunction}(line,val)
	endfor

  let b:cached_signs = results
	return results
endfunction"}}}

" vim: set fdm=marker:
