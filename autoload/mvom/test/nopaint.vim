function! mvom#test#nopaint#paint(data)
  return a:data
endfunction

function! mvom#test#nopaint#reconcile(data)
	return a:data " do nothing
endfunction
