" Options:
" TODO hls: if true, then highlight
"
" Window (show current visible window in macro area)
" TODO make the cursor location highlighting optional.

function! mvom#plugins#window#init(options)
endfunction

function! mvom#plugins#window#deinit()
endfunction

function! mvom#plugins#window#data(options)
	let firstVisible = line("w0")
	let lastVisible = line("w$")
	let totalLines = line("$")
	let currentLine = line(".")
	let results = { 'lines': {}}
  if mvom#renderer#getmacromode()
    let offsetOfCursor = mvom#util#location#ConvertToPercentOffset(currentLine,firstVisible,lastVisible,totalLines)
  else
    let offsetOfCursor = currentLine
  endif
	let n = firstVisible
	while n <= lastVisible
		let results['lines'][n] = {}
		let results['lines'][n]['count'] = 1
    if mvom#renderer#getmacromode() && offsetOfCursor == mvom#util#location#ConvertToPercentOffset(n,firstVisible,lastVisible,totalLines) 
      let results['lines'][n]['iscurrentline'] = 1
    elseif !mvom#renderer#getmacromode() && offsetOfCursor == n
      let results['lines'][n]['iscurrentline'] = 1
    endif
		let n += 1
	endwhile
	return results
endfunction

function! mvom#plugins#window#enabled(options)
	return &hls == 1
endfunction
