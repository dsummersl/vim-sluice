" Window (show current visible window in macro area)
" TODO make the cursor location highlighting optional.

function! mvom#plugins#window#init()
endfunction

function! mvom#plugins#search#deinit()
endfunction

function! mvom#plugins#window#data()
	let firstVisible = line("w0")
	let lastVisible = line("w$")
	let totalLines = line("$")
	let currentLine = line(".")
	let n = firstVisible
	let results = {}
	let offsetOfCursor = mvom#util#location#ConvertToPercentOffset(currentLine,firstVisible,lastVisible,totalLines)
	while n <= lastVisible
		let results[n] = {}
		let results[n]['count'] = 1
		if offsetOfCursor == mvom#util#location#ConvertToPercentOffset(n,firstVisible,lastVisible,totalLines) 
			let results[n]['iscurrentline'] = 1
		endif
		let n = n+1
	endwhile
	return results
endfunction

function! mvom#plugins#window#enabled()
	return &hls == 1
endfunction
