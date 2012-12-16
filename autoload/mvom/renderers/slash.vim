" Slash (//) painter

function! mvom#renderers#slash#paint(options,vals)
	return mvom#renderers#util#TypicalPaint(a:vals,a:options['chars'],a:options['color'])
endfunction

function! mvom#renderers#slash#reconcile(options,vals)
	" if its a slash or backslash then do something, otherwise, we don't care.
	" TODO this still isn't quite right - I don't think its counting correctly
	let cnt = 0
	for plugin in a:vals['plugins']
		let render = mvom#renderers#util#FindRenderForPlugin(plugin)
		if render == 'Slash' || render == 'Backslash'
			let cnt = cnt + 1
		endif
	endfor
	if cnt > 1
		let a:vals['text'] = a:options['xchars']
		let modded = mvom#util#color#RGBToHSV(mvom#util#color#HexToRGB(a:options['xcolor']))
		let modded[2] = 50+ 10*a:vals['count']/len(a:vals['plugins'])
		if modded[2] > 100
			let modded[2] = 100
		endif
		let a:vals['fg'] = mvom#util#color#RGBToHex(mvom#util#color#HSVToRGB(modded))
	end
	return a:vals
endfunction
