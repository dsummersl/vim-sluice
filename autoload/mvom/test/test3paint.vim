function! mvom#test#test3paint#paint(options,data)
	let results = {}
	for line in keys(a:data)
		let results[line] = copy(a:data[line])
		let results[line]['fg'] = 'testhi'
		let results[line]['bg'] = 'testbg'
		let results[line]['text'] = '..'
	endfor
	return results
endfunction

