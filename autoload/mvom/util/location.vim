" functions that help with location activities

" Return a list of the state of all the registers.
function! mvom#util#location#SaveRegisters()
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
function! mvom#util#location#ConvertToModuloOffset(line,start,end,total)
	let percent = (a:line-1) / str2float(a:total)
	let lines = a:end - a:start + 1
	return float2nr(percent * lines * 100) % 100
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

" Get specific details of window dimensions as a dictionary:
function! mvom#util#location#getwindowdimensions(data)
  let cached_dim = {}
	let cached_dim['top'] = line('w0')
	let cached_dim['bottom'] = line('w$')
	let cached_dim['height'] = winheight(0)
	let cached_dim['pos'] = line('.')
	let cached_dim['hls'] = &hls
	let cached_dim['data'] = a:data
  return cached_dim
endf

" Wrap a function with a memoization storage mechanism.
" If the parameters to the function match previous
"
" Parameters:
"   fn     = the funcref of the function that will be memoized.
"   hashfn = (optional) how to compute the hash for a fn hit (defaults to the
"            hash of the parameters passed to the function). the function
"            should take a list of arguments (equal to what is passed to 'fn')
"
" Returns:
"   A callable dictionary with these props/methods:
"    - call() -- take the same params as 'fn'
"    - clear() -- clear the cache
"    - .data['hits'] -- number of cache hits
"    - .data['misses'] -- number of cache hits
"
function! mvom#util#location#memoize(fn,...)
  if exists('a:1')
    let Hashfn = a:1
  else
    let Hashfn = function('mvom#util#location#dfltmemo')
  endif
  let result = { 'data': { 'hits': 0, 'misses': 0},
        \'fn': a:fn,
        \'hash': Hashfn
        \}
  function result.clear() dict
    let self.data = { 'hits': 0, 'misses': 0}
  endfunction
  function result.call(...) dict
    let hash = self.hash(a:000)
    if !has_key(self.data,hash)
      let self.data[hash] = call(self.fn,a:000)
      let self.data['misses'] += 1
    else
      let self.data['hits'] += 1
    endif
    return self.data[hash]
  endfunction
  return result
endfunction

" the default memoization hashing function.
function! mvom#util#location#dfltmemo(args)
  return mvom#util#color#hash(string(a:args))
endfunction
