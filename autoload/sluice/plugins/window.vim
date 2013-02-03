" Window (show current visible window in macro area)
"
" Options:
"   showinline: If set, then make the location where the cursor is slightly
"               darker within the scrollbar area. Default: 1
"           bg: Background. If not set, then the current screen background
"               color is used.
"     inlinebg: Background of hte 'current line'. If not set, then the current
"               'CursorLine' highlight group is used.
"

function! sluice#plugins#window#init(options)
  if !has_key(a:options,'showinline')
    let a:options['showinline'] = 1
  endif
  if !has_key(a:options,'bg')
    let a:options['bg'] = sluice#plugins#undercursor#getbg()
  endif
  if !has_key(a:options,'inlinebg')
    let inlinebg = sluice#plugins#undercursor#getcolor('guibg','CursorLine')
    let a:options['inlinebg'] = inlinebg
  endif
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
