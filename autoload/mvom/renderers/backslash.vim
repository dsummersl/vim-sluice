" Backslash (\\) painter
function! mvom#renderers#backslash#init(options)
	" same as slash
  let s:options = a:options
	call mvom#renderers#slash#init(a:options)
endfunction

function! mvom#renderers#backslash#paint(vals)
	return mvom#renderers#util#TypicalPaint(a:vals,s:options['chars'],s:options['color'])
endfunction

function! mvom#renderers#backslash#reconcile(vals)
	" same as slash
	return mvom#renderers#slash#reconcile(a:vals)
endfunction
