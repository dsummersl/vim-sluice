function! mvom#test#test3paint#paint(options,data)
	let results = {'lines': {}}
	for line in keys(a:data['lines'])
		let results['lines'][line] = copy(a:data['lines'][line])
		let results['lines'][line]['fg'] = 'testhi'
		let results['lines'][line]['bg'] = 'testbg'
		let results['lines'][line]['text'] = '..'
	endfor
	return results
endfunction

