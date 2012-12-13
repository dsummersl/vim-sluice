" Backslash (\\) painter
function! mvom#renderers#backslash#init()
	" same as slash
	call SlashInit()
endfunction

function! mvom#renderers#backslash#paint(vals)
	return mvom#renderers#util#TypicalPaint(a:vals,g:mvom_backslash_chars,g:mvom_backslash_color)
endfunction

function! mvom#renderers#backslash#reconcile(vals)
	" same as slash
	return SlashReconcile(a:vals)
endfunction
