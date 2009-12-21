" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

"
if has( "signs" ) == 0
	echohl ErrorMsg
	echo "MacroViewOfMatches requires Vim to have +signs support."
	echohl None
	finish
endif

" mappings"{{{
" TODO the folding logic messes things up - have to somehow take into account
" the folded lines or the 'green' and -- parts get all messed up.
" au VimResized * call PaintMatches(@/)

au! CursorHold * nested call RePaintMatches()
noremap / :call MacroViewStart()<CR>/
function! MacroViewStart()
	cnoremap <silent> <CR> <CR>:call MacroViewStop()<CR>
	cnoremap <silent> <Esc> <C-C>:call MacroViewStop()<CR>
endfunction
function! MacroViewStop()
	cunmap <CR>
	cunmap <Esc>
	" new search so forget we colored:
	sign unplace *
	unlet! b:cached_dimensions
	unlet! b:cached_signs
	" Now color everything up.
	call RePaintMatches()
endfunction
function! RePaintMatches()
	if !exists('b:mvom_lastsearch') " first call of anything
		let b:mvom_lastsearch = @/
		let b:cached_dimensions = {}
		let b:cached_dimensions['top'] = 0
		let b:cached_dimensions['bottom'] = 0
		let b:cached_dimensions['height'] = 0
		hi VisWin ctermfg=green ctermbg=green guifg=#00ff00 guibg=#00ff00
		hi VisMatch ctermfg=black ctermbg=green guifg=#000000 guibg=#00ff00
		hi InvisMatch ctermfg=black ctermbg=gray guifg=#000000 guibg=#bebebe

		sign define visMatch text=-- texthl=VisMatch
		sign define invisMatch text=-- texthl=InvisMatch
		sign define visWin text=..  texthl=VisWin
		return
	endif
	if !exists('b:cached_dimensions') && &hls == 1
		let b:cached_dimensions = {}
		let b:cached_dimensions['top'] = line('w0')
		let b:cached_dimensions['bottom'] = line('w$')
		let b:cached_dimensions['height'] = winheight(0)
		call PaintMatches(@/)
		return
	elseif exists('b:cached_dimensions') && &hls == 0
		call PaintMatches("")
	endif
	if &hls == 0
		unlet! b:cached_dimensions
		return
	endif
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	let winHeight = winheight(0)
	if firstVisible != b:cached_dimensions['top'] || lastVisible != b:cached_dimensions['bottom'] || winHeight != b:cached_dimensions['height']
		call PaintMatches(@/)
	endif
endfunction
"}}}
" Painting logic {{{
" paint the matches for real, on the screen. With signs.
function! PaintMatches(searchTerm)
	if len(a:searchTerm) == 0
		sign unplace *
		return
	endif
	let save_cursor = getpos(".")
	let totalLines = line('$')
	let firstVisible = line('w0')
	let lastVisible = line('w$')
	" setup all the matches in the file, percent offset wise:
	let n = 1
	1
	let searchResults = {}
	while search(a:searchTerm,"W") > 0
		let here = line('.')
		let searchResults[here] = 1
		let n = n+1
	endwhile
	call DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,"UnpaintSign","PaintSign")
	call setpos('.', save_cursor)
	let b:cached_dimensions = {}
	let b:cached_dimensions['top'] = line('w0')
	let b:cached_dimensions['bottom'] = line('w$')
	let b:cached_dimensions['height'] = winheight(0)
	let b:mvom_lastsearch = a:searchTerm
endfunction

function! PaintSign(line,type)
	let hiType = "invisMatch"
	if (a:type == 0)
		let hiType = "invisMatch"
	elseif (a:type == 1)
		let hiType = "visWin"
	elseif (a:type == 2)
		let hiType = "visMatch"
	endif
	" echom "here is ". here ." and firstVisible = ". firstVisible ." and lastVisible = ". lastVisible ." gonna do ". locinInFile
	" echom "hi with ". hiType
	exe "sign place ".a:line." name=".hiType." line=".a:line." buffer=".winbufnr(0)
endfunction
function! UnpaintSign(line)
	exe "sign unplace ".a:line." buffer=".winbufnr(0)
endfunction

" actual logic that paints the matches. painting and searching are abstracted
" out so that I can test this by itself.
function! DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction)
	if !exists('b:cached_signs') | let b:cached_signs = {} | endif
	if ( a:lastVisible - a:firstVisible + 1 >= a:totalLines )
		for line in keys(b:cached_signs)
			exe "call ".a:unpaintFunction."(".line.")"
		endfor
		let b:cached_signs = {}
		return {}
	endif
	" paint up the section that shows you where you are in the file.
	let last = ConvertToPercentOffset(a:lastVisible,a:firstVisible,a:lastVisible,a:totalLines)
	let n = ConvertToPercentOffset(a:firstVisible,a:firstVisible,a:lastVisible,a:totalLines)
	let results = {}
	while n <= last
		let results[n] = 1
		let n = n+1
	endwhile
	for [line, trash] in items(a:searchResults)
		let locinInFile = ConvertToPercentOffset(str2nr(line),a:firstVisible,a:lastVisible,a:totalLines)
		let results[locinInFile] = (line >= a:firstVisible && line <= a:lastVisible) ? 2:0
	endfor
	" paint any new things:
	for [key,val] in items(results)
		if has_key(b:cached_signs, key) && b:cached_signs[key] == val
			" if the thing has already been painted and its the same as last time
			" don't do anything at all
			call remove(b:cached_signs,key)
		else
			if has_key(b:cached_signs, key)
				call remove(b:cached_signs,key)
				exe "call ".a:unpaintFunction."(".key.")"
			end
			exe "call ".a:paintFunction."(".key.",".val.")"
		endif
	endfor
	" if there is any cruft left from the last painting, lets remove them
	for [key,val] in items(b:cached_signs)
		exe "call ".a:unpaintFunction."(".key.")"
	endfor
	let b:cached_signs = results
	return results
endfunction

" This function takes in some line number that is <= the total
" possible lines, and places it somewhere on the range between
" [start,end] depending on what percent of the match it is.
function! ConvertToPercentOffset(line,start,end,total)
	let percent = a:line / str2float(a:total)
	let lines = a:end - a:start
	return float2nr(percent * lines)+a:start
endfunction"}}}
" test functions {{{
function! TestConvertToPercentOffset()
  " put your curser in this block somwhere and then type ":call VUAutoRun()"
  call VUAssertEquals(ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(ConvertToPercentOffset(50,70,100,100),85)
endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line)
endfunction

function! TestDoPaintMatches()
	" VUAssertEquals(DoPaintMatches(totalLines,firstVisible,lastVisible,searchResults,unpaintFunction,paintFunction),{})
	call VUAssertEquals(DoPaintMatches(5,1,5,{},"UnpaintTestStub","PaintTestStub"),{})
	call VUAssertEquals(DoPaintMatches(5,1,5,{1:1},"UnpaintTestStub","PaintTestStub"),{})
	let b:cached_signs = {}
	call VUAssertEquals(DoPaintMatches(10,1,5,{1:0},"UnpaintTestStub","PaintTestStub"),{1:2,2:1,3:1})
	call VUAssertEquals(DoPaintMatches(10,6,10,{1:0,10:0},"UnpaintTestStub","PaintTestStub"),{6:0,8:1,9:1,10:2})
endfunction"}}}
" vim: set fdm=marker:
