function! sluice#test#nopaint#paint(data)
  return a:data
endfunction

function! sluice#test#nopaint#reconcile(options,values,data)
	return a:data " do nothing
endfunction
