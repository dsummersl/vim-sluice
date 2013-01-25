function! sluice#test#rrpaint#reconcile(options,values,data)
	" change it to 'R' for reconcile?
	let a:data['text'] = 'RR'
	return a:data
endfunction
