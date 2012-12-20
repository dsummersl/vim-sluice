function! mvom#test#test5plugin#data(options)
	return {'5':{'count':1},'6':{'count':2}}
endfunction

function! mvom#test#test5plugin#init(options)
endfunction

function! mvom#test#test5plugin#deinit()
endfunction


function! mvom#test#test5plugin#enabled(options)
	return 1
endfunction
