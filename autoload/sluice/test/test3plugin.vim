function! sluice#test#test3plugin#data(options)
	return {'1':{'count':1},'2':{'count':2}}
endfunction

function! sluice#test#test3plugin#init(options)
endfunction

function! sluice#test#test3plugin#deinit()
endfunction

function! sluice#test#test3plugin#enabled(options)
	return 1 
endfunction
