" Backslash (\\) painter
function! mvom#renderers#backslash#Init()
	" same as slash
	call SlashInit()
endfunction

function! mvom#renderers#backslash#Paint(vals)
	return mvom#renderers#util#TypicalPaint(a:vals,g:mvom_backslash_chars,g:mvom_backslash_color)
endfunction

function! mvom#renderers#backslash#Reconcile(vals)
	" same as slash
	return SlashReconcile(a:vals)
endfunction
