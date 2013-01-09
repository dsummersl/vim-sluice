" Slash (//) painter

function! mvom#renderers#slash#paint(options,vals)
	return mvom#renderers#util#TypicalPaint(a:vals,a:options)
endfunction

function! mvom#renderers#slash#reconcile(options,vals)
  let result = {}
  let result['text'] = a:options['xchars']
  let result['fg'] = a:options['xcolor']
	return result
endfunction
