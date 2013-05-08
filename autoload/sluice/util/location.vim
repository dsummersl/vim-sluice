" functions that help with location activities

" Return a list of the state of all the registers.
function! sluice#util#location#SaveRegisters()
	let registers={ 0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"slash": '/',"quote":'"' }
	let result = {}
	for r in keys(registers)
		let result["reg-".r] = getreg(registers[r], 1)
		let result["mode-".r] = getregtype(registers[r])
	endfor
	return result
endfunction

function! sluice#util#location#LoadRegisters(datum)
	let registers={ 0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"slash": '/',"quote":'"' }
	for r in keys(registers)
		call setreg(registers[r], a:datum["reg-".r], a:datum["mode-".r])
	endfor
endfunction

" This function takes in some line number that is <= the total
" possible lines, and places it somewhere on the range between
" [start,end] depending on what percent of the match it is.
function! sluice#util#location#ConvertToPercentOffset(line,start,end,total)
	let percent = (a:line-1) / str2float(a:total)
	let lines = a:end - a:start + 1
	return float2nr(percent * lines + a:start)
endfunction

" Same as ConvertToPercentOffset but return only the module value
" rather than the line. Down to the 100th
"
" It just says what hte partial percent would have been
" from 0..99 (.00 to .99).
"
function! sluice#util#location#ConvertToModuloOffset(line,start,end,total)
	let percent = (a:line-1) / str2float(a:total)
	let lines = a:end - a:start + 1
	return float2nr(percent * lines * 100) % 100
endfunction

function! sluice#util#location#GetHumanReadables(chars)
	let result = ""
	let n = 0
	while n < len(a:chars)
		if a:chars[n] == '/'
			let result = result . 'fs'
		elseif a:chars[n] == '\'
			let result = result . 'bs'
		elseif a:chars[n] == '.'
			let result = result . 'dt'
		elseif a:chars[n] == '#'
			let result = result . 'hsh'
		elseif a:chars[n] == '-'
			let result = result . 'da'
		else
			let result = result . a:chars[n]
		end
		let n = n + 1
	endwhile
	return result
endfunction

" Get specific details of window dimensions as a dictionary:
"
" Note: height > bottom - top when folds exist, or you're at the bottom of the
" screen or...
function! sluice#util#location#getwindowdimensions(data)
  let cached_dim = {}
	let cached_dim['top'] = line('w0')
	let cached_dim['bottom'] = line('w$')
	let cached_dim['height'] = winheight(0)
	let cached_dim['pos'] = line('.')
	let cached_dim['data'] = a:data
  return cached_dim
endf
