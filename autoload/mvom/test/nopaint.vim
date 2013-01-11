function! mvom#test#nopaint#paint(data)
  return a:data
endfunction

function! mvom#test#nopaint#reconcile(options,values,data)
	return a:data " do nothing
endfunction
