" UnderCursor: show matches for the 'word' the cursor is currently on
function! sluice#plugins#undercursor#init(options)
  call sluice#plugins#search#init(a:options)
  " get the background color, and make it darker or lighter depending on
  " the 'background' setting.
  let bg = sluice#plugins#undercursor#getbg()
  if &background == 'dark'
    let cmd = "highlight! UnderCursor guibg=#". sluice#util#color#lighter(bg)
  else
    let cmd = "highlight! UnderCursor guibg=#". sluice#util#color#darker(bg)
  endif
  exe cmd
	exe "autocmd BufNewFile,BufRead * ". cmd
  let a:options['bg'] = bg
endfunction

function! sluice#plugins#undercursor#getbg()
  let currenthi=''
  redir => currenthi
  silent! highlight Normal
  redir END

  for line in split(currenthi,'\n')
    for part in split(line,' ')
      let ab = split(part,'=')
      if len(ab) == 2 && ab[0] == 'guibg'
        return substitute(ab[1],'#','','')
      endif
    endfor
  endfor
  " TODO if CSApprox exists, then compute the bg from the ctermbg
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
