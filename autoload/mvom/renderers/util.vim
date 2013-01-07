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

function! mvom#renderers#util#TypicalPaint(vals,options)
	let result = {}
	for line in keys(a:vals)
		let result[line] = { 'text': a:options['chars'], 'fg': a:options['color'], 'bg':g:mvom_default_bg }
    for key in ["iconcolor","iconwidth","iconalign"]
      if has_key(a:options,key)
        let result[line][key] = a:options[key]
      endif
    endfor
	endfor
	return result
endfunction

