" functions that help with location activities

" Return a list of the state of all the registers.
function! mvom#util#location#SaveRegisters()
	" TODO the a-z registers should be saved too? Myabe not..only if the plugin
	" uses them.
	let registers={ 0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"slash": '/',"quote":'"' }
	let result = {}
	for r in keys(registers)
		let result["reg-".r] = getreg(registers[r], 1)
		let result["mode-".r] = getregtype(registers[r])
	endfor
	return result
endfunction

function! mvom#util#location#LoadRegisters(datum)
	let registers={ 0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"slash": '/',"quote":'"' }
	for r in keys(registers)
		call setreg(registers[r], a:datum["reg-".r], a:datum["mode-".r])
	endfor
endfunction

" This function takes in some line number that is <= the total
" possible lines, and places it somewhere on the range between
" [start,end] depending on what percent of the match it is.
function! mvom#util#location#ConvertToPercentOffset(line,start,end,total)
	let percent = a:line / str2float(a:total)
	let lines = a:end - a:start
	return float2nr(percent * lines)+a:start
endfunction

function! mvom#util#location#GetHumanReadables(chars)
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

