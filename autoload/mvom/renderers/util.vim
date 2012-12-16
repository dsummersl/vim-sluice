function! mvom#renderers#util#FindPlugin(dataPlugin)
	for plugin in g:mv_plugins
		if plugin['plugin'] == a:dataPlugin
			return plugin
		endif
	endfor
endfunction

function! mvom#renderers#util#FindRenderForPlugin(dataPlugin)
  return mvom#renderers#util#FindPlugin(a:dataPlugin)['options']['render']
endfunction

function! mvom#renderers#util#TypicalPaint(vals,slashes,matchColor)
	let modded = mvom#util#color#RGBToHSV(mvom#util#color#HexToRGB(a:matchColor))
	let result = {}
	for line in keys(a:vals)
		let modded[2] = 60 + 10*a:vals[line]['count']/len(a:vals[line]['plugins'])
		if modded[2] > 100
			let modded[2] = 100
		endif
		let thecolor = mvom#util#color#RGBToHex(mvom#util#color#HSVToRGB(modded))
		let result[line] = { 'text': a:slashes, 'fg': thecolor, 'bg':g:mvom_default_bg }
	endfor
	return result
endfunction

