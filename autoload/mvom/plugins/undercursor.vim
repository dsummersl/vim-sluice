" Options:
"   fg: foreground color
"   bg: background color

" UnderCursor: show matches for the 'word' the cursor is currently on
function! mvom#plugins#undercursor#init(options)
  call mvom#plugins#search#init(a:options)
  " TODO support coloring for cterm
	exe "highlight! UnderCursor ctermbg=1 guifg=#".a:options['fg'] ." guibg=#". a:options['bg']
	exe "autocmd BufNewFile,BufRead * highlight! UnderCursor guifg=#". a:options['fg'] ." guibg=#". a:options['bg']
endfunction

function! mvom#plugins#undercursor#deinit()
  " TODO remove the autocommands and the highlight
  " TODO also make the undercursor highlighting optional
endfunction

function! mvom#plugins#undercursor#data(options)
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
    let results=mvom#plugins#search#data(opts)
    execute 'silent syntax clear UnderCursor'
    execute 'syntax match UnderCursor "'. opts['needle'] .'" containedin=ALL'
    return results
  finally
    let @g=oldg
  endtry
endfunction

function! mvom#plugins#undercursor#enabled(options)
	if &hls == 0 || (exists('w:mvom_lastcalldisabled') && w:mvom_lastcalldisabled)
		execute 'silent syntax clear UnderCursor'
	endif
	return &hls == 1
endfunction
