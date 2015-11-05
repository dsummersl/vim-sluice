function! sluice#renderer#RePaintMatches()"{{{
	let painted = 0
	if !sluice#renderer#getenabled()
		return painted
	endif
	let w:save_cursor = winsaveview()
	let w:save_registers = sluice#util#location#SaveRegisters()
	let totalLines = line('$')
	let firstVisible = line('w0')
	let lastVisible = line('w$')
  let current_dims = sluice#util#location#getwindowdimensions(sluice#renderer#CombineData(g:mv_plugins,totalLines,firstVisible,lastVisible))
	" if there are no cached_dim then this is the first call to the
	" repaintfunction. Make the cache and paint.
	if !exists('w:cached_dim')
		let w:cached_dim = current_dims
		call sluice#renderer#PaintMV(w:cached_dim['data'])
		" TODO possible optimization: don't restore the view if it hasn't changed?
		call winrestview(w:save_cursor)
		" TODO ditto for load registers?
		call sluice#util#location#LoadRegisters(w:save_registers)
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
        \current_dims['data'] != w:cached_dim['data']
		call sluice#renderer#PaintMV(current_dims['data'])
		let painted = 1
	endif
	let w:cached_dim = current_dims
	call winrestview(w:save_cursor)
	call sluice#util#location#LoadRegisters(w:save_registers)
	return painted
endfunction"}}}

" Set the status of the Sluice plugin in the current buffer.
" Sends a warning if the plugin is currently disabled.
function! sluice#renderer#setenabled(enable)
  let b:sluice_enabled = a:enable
  if !exists('b:sluice_macromode')
    let b:sluice_macromode = g:sluice_default_macromode
  endif
  if sluice#renderer#getenabled()
    let bg = sluice#util#color#get_default_bg()
    highlight clear SignColumn
    exe printf("highlight SignColumn guifg=#%s guibg=#%s",bg,bg)
    for p in g:mv_plugins
      let options = p['options']
      call {options['data']}#init(options)
    endfor
    if exists('b:sluice_signs') | unlet b:sluice_signs | endif
    call sluice#renderer#RePaintMatches()
  else
    " remove any signs
		sign unplace *
    " let the plugins clean up
    for p in g:mv_plugins
      let options = p['options']
      call {options['data']}#deinit()
    endfor
  endif
  return b:sluice_enabled
endfunction

"score Get the status of the Sluice plugin in the current buffer.
function! sluice#renderer#getenabled()
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
  if !exists('g:sluice_enabled')
    return 0
  endif
  if !g:sluice_enabled
    return 0
  endif
  if !exists('b:sluice_enabled')
    return sluice#renderer#setenabled(g:sluice_default_enabled)
  endif
  return b:sluice_enabled
endfunction

" Change whether this is in 'macro mode' or non macro mode.
"
" Toggles the setting, and returns true/false based on the new
" status.
function! sluice#renderer#setmacromode(enable)
  let b:sluice_macromode = a:enable
endfunction

function! sluice#renderer#getmacromode()
  if !exists('b:sluice_macromode')
    let b:sluice_macromode = g:sluice_default_macromode
  endif
  return b:sluice_macromode
endfunction

" }}}

" paint the matches for real, on the screen. With signs.
function! sluice#renderer#PaintMV(data)"{{{
	if !exists('g:mv_plugins') | return | endif
	let totalLines = line('$')
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	let anyEnabled = 0
	for pluginInstance in g:mv_plugins
		let options = pluginInstance['options']
		let plugin = options['data']
		if options['enabled'] && {plugin}#enabled(options)
			let anyEnabled = 1
			break
		endif
	endfor
	if &buftype == "help" || &buftype == "nofile" || &diff == 1 || &buftype == 'quickfix'
		" situations in which we don't want this: help files, nofiles, diff mode
		let anyEnabled = 0
	endif
	if anyEnabled
		call sluice#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,a:data,"sluice#renderer#UnpaintSign","sluice#renderer#PaintSign")
		let w:sluice_lastcalldisabled = 0
	else
		let w:sluice_lastcalldisabled = 1
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
" 	  }
" 	}
" }
function! sluice#renderer#CombineData(plugins,totalLines,firstVisible,lastVisible)"{{{
	let allData = {}
	let resultData = {}
  let resultData['lines'] = {}
  let resultData['gutterImage'] = sluice#renderers#icon#makeImage(g:sluice_pixel_density,g:sluice_pixel_density*a:totalLines)

  " Generate data for each plugin (if its enabled), and combine it into one master list:
	for pluginInstance in a:plugins"{{{
		let options = pluginInstance['options']
		let name = pluginInstance['name']
		let plugin = options['data']
		if !options['enabled'] || !{plugin}#enabled(options)
			continue
		endif
		call winrestview(w:save_cursor) " so the plugins all get to start from the same 'window'
		let data={plugin}#data(options)
    " TODO search hplugins have other keys apart from 'lines'. And these keys
    " need to be around for the renderer to use. This method needs to copy all
    " the data to allData so that it can be put into the final
    " resultData...the TypicalPaint method is waiting for this...
		for line in keys(data['lines']) " loop through all the data and add it to my own master list.
			if has_key(allData,line)
        let allData[line][name] = data['lines'][line]
				let allData[line]['count'] = allData[line]['count'] + 1
			else
        " do we have the current plugin already? If not:
				let allData[line] = {}
				let allData[line]['count'] = 1
				let allData[line][name] = data['lines'][line]
			endif
		endfor
	endfor"}}}

  " setup the background color for the image:
  let defaultbg = sluice#util#color#get_default_bg()
  if len(defaultbg) == 0
    let defaultbg = sluice#util#color#getbg()
  endif
  call resultData['gutterImage'].addRectangle(defaultbg,0,0,g:sluice_pixel_density,g:sluice_pixel_density*a:totalLines)

  " compute the current 'height' of the window. that would be used by an
  " icon so that a line can be accurately rendered (TODO if the height is big it
  " should really 'fall' into the next line).
  if sluice#renderer#getmacromode()
    let pixelsperline = g:sluice_pixel_density / (a:totalLines / (1.0*(a:lastVisible - a:firstVisible + 1)))
  else
    let pixelsperline = g:sluice_pixel_density
  endif
  let resultData['pixelsperline'] = pixelsperline

  " Generate the paint data"{{{
	for pluginInstance in a:plugins " now render everything
		let render = pluginInstance['options']['render']
		let plugin = pluginInstance['options']['data']
		let name = pluginInstance['name']
		let pluginData = {}
    let pluginData['gutterImage'] = resultData['gutterImage']
    let pluginData['pixelsperline'] = resultData['pixelsperline']
    let pluginData['lines'] = {}
    " Make a list of the lines that actually have plugin data present:
		for line in keys(allData)
      if sluice#renderer#getmacromode()
        let signLine = sluice#util#location#ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
        let modulo = float2nr(sluice#util#location#ConvertToModuloOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines) / 100.0 * g:sluice_pixel_density)
      else
        let signLine = str2nr(line)
        let modulo = 0
      endif
			if has_key(allData[line],name) > 0
				let pluginData['lines'][line] = allData[line][name]
        let pluginData['lines'][line]['modulo'] = modulo
        let pluginData['lines'][line]['line'] = str2nr(line)
        let pluginData['lines'][line]['signLine'] = signLine
			endif
		endfor
    " TODO it looks like this gets called twice on an update. Yikes.
		let paintData = {render}#paint(pluginInstance['options'],pluginData)
    " once painted, store the results.
		for line in keys(paintData['lines'])
			if !has_key(resultData['lines'],line)
				let resultData['lines'][line] = {}
			endif
      let resultData['lines'][line][name] = copy(allData[line][name])
      for value in keys(paintData['lines'][line])
        let resultData['lines'][line][name][value] = paintData['lines'][line][value]
      endfor
		endfor
	endfor"}}}
	return resultData
endfunction"}}}
" paint functions {{{
function! sluice#renderer#PaintSign(line,dict)
	if has_key(a:dict,'fg')
		let thesign=a:dict['hash']
    exe printf("sign place %s name=%s line=%s buffer=%s",a:line,a:dict['hash'],a:line,winbufnr(0))
	else
		" if 'visible' then this is a non-matching line that's currently
		" 'visible'.
	endif
endfunction

function! sluice#renderer#UnpaintSign(line,dict)
	exe "sign unplace ".a:line." buffer=".winbufnr(0)
endfunction

"}}}
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
function! sluice#renderer#DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)"{{{
	if !exists('b:sluice_signs') | let b:sluice_signs = {} | endif
	let results = {}
  let new_signs = {}

	" First collate all of the search results into one hash where the 'macro line'
  " number points to all matching search results.
  "
  " Additional keys added:
  " - plugins: all matching search results
  " - visible: if 1, then the results are currently visible in the window.
	for [line, data] in items(a:searchResults['lines'])
    if sluice#renderer#getmacromode()
      let signLine = sluice#util#location#ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
    else
      let signLine = line
    endif

    " setup the results if they aren't already setup:
		if !has_key(results,signLine)
			let results[signLine] = {}
			let results[signLine]['plugins'] = []
		endif

    " if the line is within the visible range, mark it 'visible':
    let results[signLine]['visible'] = (line >= a:firstVisible && line <= a:lastVisible) ? 1:0

    " setup the top level data values that are ultimately used for the signs
    " (the combination of all the plugins).
    for plugin in keys(data)
      call add(results[signLine]['plugins'],data[plugin])
      let offset = len(results[signLine]['plugins'])-1
      for key in keys(data[plugin])
        let results[signLine][key] = data[plugin][key]
      endfor
      let results[signLine]['plugins'][offset]['plugin'] = plugin
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
        let render = sluice#renderers#util#FindRenderForPlugin(p['plugin'])
        let plugin = sluice#renderers#util#FindPlugin(p['plugin'])
        let reconciled = {render}#reconcile(plugin['options'],val['plugins'],p)
        for key in keys(reconciled)
          let results[line][key] = reconciled[key]
        endfor
      endfor
      " its important that the window be place LAST otherwise the fg/bg
      " gets clobbered.
      "
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

  " Setup highlighting
	for [line,val] in items(results)
    " Ensure there are defaults.
		if !has_key(val,'text') | let val['text'] = '..' | endif
		if !has_key(val,'fg') | let val['fg'] = val['bg'] | endif

    " TODO this is allslightly better than nothing...but totally broke. We
    " need to pull cterms when there is no gui-ness and somehow make cterms
    " darker/lighter depending on the situation. I think?
 
    " when there is no fg, assume this is a console vim and should be
    " 'invisible' and use the Normal highlight background.
    let fg = ''
    if has_key(val,'fg')
      let fg = 'guifg=#'. val['fg']
    else
      if sluice#util#color#getcolor('guibg','Normal') != 0
        let fg = 'guifg='. sluice#util#color#getcolor('guibg','Normal')
      else
        let fg = 'ctermfg='. sluice#util#color#getcolor('ctermbg','Normal')
      endif
    endif

    " when there is no bg, assume this is a console vim and use ctermbg
    let bg = ''
    if has_key(val,'bg')
      let bg = 'guibg=#'. val['bg']
    else
      if sluice#util#color#getcolor('guibg','Normal') != 0
        let bg = 'guifg='. sluice#util#color#getcolor('guibg','Normal')
      else
        let bg = 'ctermfg='. sluice#util#color#getcolor('ctermbg','Normal')
      endif
    endif
    exe printf("highlight! %s %s %s",sluice#util#color#GetHighlightName(val),fg,bg)
  endfor

  " I'm lazy, and CSApprox works so well at turning GUI colors into cterm
  " colors. I leave it to it to fix my highlights!
  if !has('gui_running') && exists(':CSApprox')
    silent exec ":CSApprox"
  endif

  " after the gutterimage is completely painted, define any missing
  " icon/signs, and then paint.
	for [line,val] in items(results)
    let fname = a:searchResults['gutterImage'].generateHash(0,g:sluice_pixel_density*(line-1),g:sluice_pixel_density,g:sluice_pixel_density)
    let results[line]['hash'] = fname
    let new_signs[line] = fname

    " if no icon has been made, and we can do it. then create the icon:
    if !exists('g:sluice_sign_'. fname)
      "call VULog( "let g:sluice_sign_". fname ."=1")
      exe "let g:sluice_sign_". fname ."=1"
      if g:sluice_imagemagic_supported 
        " if an icon doesn't exist yet, generate it.
        if !filereadable(g:sluice_icon_cache . fname .'.png')
          " place the background color
          " DEBUG print the whole gutter. One long strip: :)
          "call a:searchResults['gutterImage'].generatePNGFile(g:sluice_icon_cache . 'gutter')
          call a:searchResults['gutterImage'].generatePNGFile(g:sluice_icon_cache . fname,0,g:sluice_pixel_density*(line-1),g:sluice_pixel_density,g:sluice_pixel_density)
        endif
        let results[line]['icon'] = g:sluice_icon_cache . fname .'.png'
        exe printf("sign define %s icon=%s text=%s texthl=%s",fname,results[line]['icon'],val['text'],sluice#util#color#GetHighlightName(val))
      else
        exe printf("sign define %s text=%s texthl=%s",fname,val['text'],sluice#util#color#GetHighlightName(val))
      endif
    endif
	endfor

  " TODO when the buffer is re-entered it should be completely repainted.
  " Check/paint all the gutter lines
  let t = ''
  for line in range(a:firstVisible,a:lastVisible)
    let t = t .'|'. line .':'
    if has_key(new_signs,line) && 
          \has_key(b:sluice_signs,line) &&
          \new_signs[line] != b:sluice_signs[line]
      call {a:paintFunction}(line,results[line])
      let t = t . new_signs[line]
    elseif has_key(new_signs,line) && !has_key(b:sluice_signs,line)
      let t = t .'+'. results[line]['hash']
      call {a:paintFunction}(line,results[line])
    elseif !has_key(new_signs,line) 
      " no sign, take away anything on that line
      "echom "WARNING: line ". line ." has no sign."
      let t = t . '-'
      call {a:unpaintFunction}(line,{})
    else
      let t = t . '.'
      " new_signs has the key, but it must have matched somehow.
    endif
  endfor
  "echom t

  " TODO there is a problem where if you are adding files in micro mode the
  " new rows don't get the background coloring added to them.
  "
  " TODO also the undurcursor doesn't un-highlight when you go to a
  " non-underword area.

  let b:sluice_signs = new_signs
	return new_signs
endfunction"}}}

" vim: set fdm=marker:
