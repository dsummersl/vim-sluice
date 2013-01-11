function! mvom#test#test3paint#paint(options,plugin)
	let results = {'lines': {}}
	for line in keys(a:plugin['lines'])
		let results['lines'][line] = copy(a:plugin['lines'][line])
		let results['lines'][line]['fg'] = 'testhi'
		let results['lines'][line]['bg'] = 'testbg'
		let results['lines'][line]['text'] = '..'
	endfor
	return results
endfunction

