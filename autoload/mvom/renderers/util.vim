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

" Perform text placement and image placement. This covers most cases of what
" one would need to do to paint to the gutter.
"
" It supports several paint modes: plain text icons, and graphical icons (with
" alignment, coloring, etc).
"
" Parameters:
"   vals   : Dictionary of lines. Keys:
"     'lines': Dictionary of line numbers. The presence of the line number is
"              all that is needed.
"     'gutterImage': the graphical representation of the gutter.
"     'pixelsperline': the computed pixels per line
"     'upmax': TODO hint to show that there could be more matches upwards
"     'downmax': TODO hint to show that there could be more matches downwards
"     
"   options: Required values for this dictionary:
"     'color': The foreground color of the icon.
"     'chars': The two characters that should go into the gutter.
"
" Returns: A dictionary compatible with a renderer function ('lines' key
" properly populated).
function! mvom#renderers#util#TypicalPaint(vals,options)
	let result = {}
  let result['lines'] = {}
  let defaultbg = g:mvom_default_bg
  if len(defaultbg) == 0
    let defaultbg = mvom#plugins#undercursor#getbg()
  endif
  let min = {}
  let max = {}
  " find the min and max values in case we need to draw dash-ee lines
  " for 'more searches...'
	for line in keys(a:vals['lines'])
    if !has_key(max,'line') ||
          \max['line'] < line ||
          \(max['line'] == line && max['modulo'] < a:vals['lines'][line]['modulo'])
      let max = copy(a:vals['lines'][line])
      let max['line'] = line
    endif
    if !has_key(min,'line') ||
          \min['line'] > line ||
          \(min['line'] == line && min['modulo'] > a:vals['lines'][line]['modulo'])
      let min = copy(a:vals['lines'][line])
      let min['line'] = line
    endif
  endfor
	for line in keys(a:vals['lines'])
    " TODO group the lines into ranges 1-10, etc...and then just paint ONE
    " rectangle for the range.
		let result['lines'][line] = { 'text': a:options['chars'], 'fg': a:options['color'], 'bg': defaultbg }
    for key in ["iconcolor","iconwidth","iconalign"]
      if has_key(a:options,key)
        let result['lines'][line][key] = a:options[key]
      endif
    endfor
    " paint a graphic icon, if icon settings are present.
    if has_key(a:options,'iconcolor')
      " if this is a min/max line and there is an upmax/downmax condition...
      if     (line == min['line'] && 
            \  has_key(a:vals,'upmax') && a:vals['upmax'] &&
            \  min['modulo'] == a:vals['lines'][line]['modulo']
            \) ||
            \(line == max['line'] &&
            \  has_key(a:vals,'downmax') && a:vals['downmax'] &&
            \  max['modulo'] == a:vals['lines'][line]['modulo']
            \)
        let dashdistance = float2nr(g:mvom_pixel_density / (1.0*a:options['iconwidth'])) / 2
        call a:vals['gutterImage'].placeRectangle(a:options['iconcolor'],
              \a:vals['lines'][line]['modulo']+g:mvom_pixel_density*(a:vals['lines'][line]['signLine']-1),
              \a:options['iconwidth'],
              \a:vals['pixelsperline'],a:options['iconalign'],
              \"fill-opacity:0.3; stroke-dasharray=\"". dashdistance .",". dashdistance ."\"",'rx="1" ry="1"')
        " TODO also make the text icon a couple of dots or something.
      else
        call a:vals['gutterImage'].placeRectangle(a:options['iconcolor'],
              \a:vals['lines'][line]['modulo']+g:mvom_pixel_density*(a:vals['lines'][line]['signLine']-1),
              \a:options['iconwidth'],
              \a:vals['pixelsperline'],a:options['iconalign'],"fill-opacity:0.7;",'rx="1" ry="1"')
      endif
    else
      " TODO do some default painting. a brick for the whole thing maybe.
    endif
	endfor
	return result
endfunction
