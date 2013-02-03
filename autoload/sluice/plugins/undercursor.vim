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
  let bg = sluice#plugins#undercursor#getcolor('guifg','Search')
  let color = sluice#util#color#lighter(bg)
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

" Get the normal background color
"
" Returns: color of highlight.
function! sluice#plugins#undercursor#getbg()
  return sluice#plugins#undercursor#getcolor('guibg','Normal')
endfunction

function! sluice#plugins#undercursor#getcolor(part,hi)
  let currenthi=''
  redir => currenthi
  exe "silent! highlight ". a:hi
  redir END

  for line in split(currenthi,'\n')
    for part in split(line,' ')
      let ab = split(part,'=')
      if len(ab) == 2 && ab[0] == a:part
        return substitute(ab[1],'#','','')
      endif
    endfor
  endfor
  " TODO if CSApprox exists, then compute the bg from the ctermbg
  " throw an exception here and let the caller decide what to do.
  return 'ffffff'
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
    let results=sluice#plugins#search#data(opts)
    execute 'silent syntax clear UnderCursor'
    execute 'syntax match UnderCursor "'. opts['needle'] .'" containedin=ALL'
    return results
  finally
    let @g=oldg
  endtry
endfunction

function! sluice#plugins#undercursor#enabled(options)
	if &hls == 0 || (exists('w:sluice_lastcalldisabled') && w:sluice_lastcalldisabled)
		execute 'silent syntax clear UnderCursor'
	endif
	return &hls == 1
endfunction
