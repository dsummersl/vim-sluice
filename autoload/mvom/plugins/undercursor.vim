" Options:
"   fg: foreground color
"   bg: background color

" UnderCursor: show matches for the 'word' the cursor is currently on
function! mvom#plugins#undercursor#init(options)
  call mvom#plugins#search#init(a:options)
	exe "highlight! UnderCursor guifg=#".a:options['fg'] ." guibg=#". a:options['bg']
	exe "autocmd BufNewFile,BufRead * highlight! UnderCursor guifg=#". a:options['fg'] ." guibg=#". a:options['bg']
endfunction

function! mvom#plugins#undercursor#deinit()
  " TODO remove the autocommands and the highlight
  " TODO also make the undercursor highlighting optional
endfunction

function! mvom#plugins#undercursor#data()
	" TODO words that are reserved aren't hilighted (probably b/c they're
	" already hilighted for their language...how do I add my highlighting to
	" theirs?
  let old_search=@/
  let oldg = @g
	exe 'silent normal! "gyl'
	let charundercursor=@g
  try
    if match(charundercursor,'\k') == -1
      " if the char under the cursor isn't part of the 'isword' then don't
      " search
      execute 'silent syntax clear UnderCursor'
      return {}
    endif
    exe "silent normal! *"
    let results=mvom#plugins#search#data()
    execute 'silent syntax clear UnderCursor'
    execute 'syntax match UnderCursor "'. @/ .'" containedin=ALL'
    return results
  finally
    let @g=oldg
    let @/=old_search
  endtry
endfunction

function! mvom#plugins#undercursor#enabled()
	if &hls == 0 || (exists('w:mvom_lastcalldisabled') && w:mvom_lastcalldisabled)
		execute 'silent syntax clear UnderCursor'
	endif
	return &hls == 1
endfunction
