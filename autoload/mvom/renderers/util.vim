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
  let result['lines'] = {}
	for line in keys(a:vals['lines'])
		let result['lines'][line] = { 'text': a:options['chars'], 'fg': a:options['color'], 'bg':g:mvom_default_bg }
    for key in ["iconcolor","iconwidth","iconalign"]
      if has_key(a:options,key)
        let result['lines'][line][key] = a:options[key]
      endif
    endfor
    " paint a graphic icon, if icon settings are present.
    if has_key(a:options,'iconcolor')
      call a:vals['gutterImage'].placeRectangle(a:options['iconcolor'],
            \a:vals['lines'][line]['modulo']+g:mvom_pixel_density*(a:vals['lines'][line]['signLine']-1),
            \a:options['iconwidth'],
            \a:vals['pixelsperline'],a:options['iconalign'],"fill-opacity:0.7;",'rx="1" ry="1"')
    else
      " TODO do some default painting. a brick for the whole thing maybe.
    endif
	endfor
	return result
endfunction

