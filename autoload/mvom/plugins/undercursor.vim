
" UnderCursor: show matches for the 'word' the cursor is currently on
function! mvom#plugins#underscore#init()
	exe "highlight! UnderCursor guifg=#".g:mvom_undercursor_fg ." guibg=#". g:mvom_undercursor_bg
	exe "autocmd BufNewFile,BufRead * highlight! UnderCursor guifg=#".g:mvom_undercursor_fg ." guibg=#". g:mvom_undercursor_bg
endfunction

function! mvom#plugins#search#deinit()
  " TODO remove the autocommands and the highlight
  " TODO also make the undercursor highlighting optional
endfunction

function! mvom#plugins#underscore#data()
	" TODO words that are reserved aren't hilighted (probably b/c they're
	" already hilighted for their language...how do I add my highlighting to
	" theirs?
	exe 'silent normal! "0yl'
	let charundercursor=@0
	if match(charundercursor,'\k') == -1
		" if the char under the cursor isn't part of the 'isword' then don't
		" search
		execute 'silent syntax clear UnderCursor'
		return {}
	endif
	let old_search=@/
	exe "silent normal! *"
	let results=mvom#plugins#search#data()
  execute 'silent syntax clear UnderCursor'
	execute 'syntax match UnderCursor "'. @/ .'" containedin=ALL'
	let @/=old_search
	return results
endfunction

function! mvom#plugins#underscore#enabled()
	if &hls == 0 || (exists('w:mvom_lastcalldisabled') && w:mvom_lastcalldisabled)
		execute 'silent syntax clear UnderCursor'
	endif
	return &hls == 1
endfunction
