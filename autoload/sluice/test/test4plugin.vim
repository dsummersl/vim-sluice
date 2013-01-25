function! sluice#test#test4plugin#data(options)
	return {'1':{'count':1,'isvis':1},'2':{'count':2}}
endfunction

function! sluice#test#test4plugin#init(options)
endfunction

function! sluice#test#test4plugin#deinit()
endfunction

function! sluice#test#test4plugin#enabled(options)
	return 1 
endfunction
