" UnderCursor: show matches for the 'word' the cursor is currently on
"
" Colors:
"    Colors for the render will automatically be selected for
"    color/xcolor/iconcolor if none are provided in the options. The colors
"    will be selected to relate to the 'Search' highlight group.

function! sluice#plugins#undercursor#init(options)
  " get the background color, and make it darker or lighter depending on
  " the 'background' setting.
  "
  " Choose the Search highlight group for the default colors but make it
  " slightly darker or lighter than that group so its different than the
  " search plugin.
  let color = sluice#util#color#getcolor('guibg','Normal')
  " TODO watch the background setting - if it changes, re-init
  if &background == 'dark'
    let color = sluice#util#color#lighter(color)
  else
    let color = sluice#util#color#darker(color)
  endif
  let cmd = "highlight! UnderCursor guibg=#". color
  exe cmd
	exe "autocmd BufNewFile,BufRead * ". cmd
  let a:options['bg'] = color
  if !has_key(a:options,'color')
    let a:options['color'] = color
  endif
  if !has_key(a:options,'xcolor')
    let a:options['xcolor'] = color
  endif
  if !has_key(a:options,'iconcolor')
    let a:options['iconcolor'] = color
  endif
  call sluice#plugins#search#init(a:options)
endfunction

function! sluice#plugins#undercursor#deinit()
  " remove the autocommands and the highlight
  highlight clear UnderCursor
  " TODO also make the undercursor highlighting optional
endfunction

function! sluice#plugins#undercursor#data(options)
	" TODO words that are reserved aren't hilighted (probably b/c they're
	" already hilighted for their language...how do I add my highlighting to
	" theirs?
  let oldg = @g
	exe 'silent normal! "gyiw'
	let wordundercursor=@g
	let charundercursor=substitute(@g,'^\v(\w).*$','\=submatch(1)',"")
  try
    if match(charundercursor,'\k') == -1 || len(@/) == 0
      " if the char under the cursor isn't part of the 'isword' then don't
      " search
      execute 'silent syntax clear UnderCursor'
      return {'lines':{}}
    endif
    let opts = copy(a:options)
    let opts['needle'] = '\<'. wordundercursor .'\>'
    if !sluice#renderer#getmacromode()
      unlet opts.max_searches
      let dims = sluice#util#location#getwindowdimensions({})
      let opts.upmax = dims.pos - dims.top + 1
      let opts.downmax = dims.bottom - dims.pos + 1
    endif
    let results=sluice#plugins#search#data(opts)
    execute 'silent syntax clear UnderCursor'
    execute 'syntax match UnderCursor "'. opts['needle'] .'" containedin=ALL'
    return results
  finally
    let @g=oldg
  endtry
endfunction

function! sluice#plugins#undercursor#enabled(options)
	if (exists('w:sluice_lastcalldisabled') && w:sluice_lastcalldisabled)
		execute 'silent syntax clear UnderCursor'
	endif
	return 1
endfunction
