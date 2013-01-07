" Slash (//) painter

function! mvom#renderers#slash#paint(options,vals)
	return mvom#renderers#util#TypicalPaint(a:vals,a:options)
endfunction

function! mvom#renderers#slash#reconcile(options,vals)
  let a:vals['text'] = a:options['xchars']
  let a:vals['fg'] = a:options['xcolor']
	return a:vals
endfunction
