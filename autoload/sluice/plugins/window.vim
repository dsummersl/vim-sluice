" Window (show current visible window in macro area)
" TODO make the cursor location highlighting optional.

function! sluice#plugins#window#init(options)
endfunction

function! sluice#plugins#window#deinit()
endfunction

function! sluice#plugins#window#data(options)
	let firstVisible = line("w0")
	let lastVisible = line("w$")
	let totalLines = line("$")
	let currentLine = line(".")
	let results = { 'lines': {}}
  if sluice#renderer#getmacromode()
    let offsetOfCursor = sluice#util#location#ConvertToPercentOffset(currentLine,firstVisible,lastVisible,totalLines)
  else
    let offsetOfCursor = currentLine
  endif
	let n = firstVisible
	while n <= lastVisible
		let results['lines'][n] = {}
		let results['lines'][n]['count'] = 1
    if sluice#renderer#getmacromode() && offsetOfCursor == sluice#util#location#ConvertToPercentOffset(n,firstVisible,lastVisible,totalLines) 
      let results['lines'][n]['iscurrentline'] = 1
    elseif !sluice#renderer#getmacromode() && offsetOfCursor == n
      let results['lines'][n]['iscurrentline'] = 1
    endif
		let n += 1
	endwhile
	return results
endfunction

function! sluice#plugins#window#enabled(options)
	return 1
endfunction
