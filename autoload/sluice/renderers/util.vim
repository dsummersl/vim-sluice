function! sluice#renderers#util#FindPlugin(dataPlugin)
	for plugin in g:mv_plugins
		if plugin['plugin'] == a:dataPlugin
			return plugin
		endif
	endfor
endfunction

function! sluice#renderers#util#FindRenderForPlugin(dataPlugin)
  return sluice#renderers#util#FindPlugin(a:dataPlugin)['options']['render']
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
function! sluice#renderers#util#TypicalPaint(vals,options)
	let result = {}
  let result['lines'] = {}
  let defaultbg = sluice#util#color#get_default_bg()
  if len(defaultbg) == 0
    let defaultbg = sluice#util#color#getbg()
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

  " place all the normal text chars an dcolors:
	for line in keys(a:vals['lines'])
		let result['lines'][line] = { 'text': a:options['chars'], 'fg': a:options['color'], 'bg': defaultbg }
    for key in ["iconcolor","iconwidth","iconalign"]
      if has_key(a:options,key)
        let result['lines'][line][key] = a:options[key]
      endif
    endfor
  endfor

  " place the graphics for all the lines. group into ranges of areas so we can
  " paint minimal rectangles.
  let sorted = _#sort(keys(a:vals['lines']),2)
  let groups = sluice#renderers#util#groupNumbers(sorted)
  for group in groups
    " paint a graphic icon, if icon settings are present.
    if has_key(a:options,'iconcolor')
      " if this is a min/max line and there is an upmax/downmax condition...
      "if     (line == min['line'] && 
      "      \  has_key(a:vals,'upmax') && a:vals['upmax'] &&
      "      \  min['modulo'] == a:vals['lines'][line]['modulo']
      "      \) ||
      "      \(line == max['line'] &&
      "      \  has_key(a:vals,'downmax') && a:vals['downmax'] &&
      "      \  max['modulo'] == a:vals['lines'][line]['modulo']
      "      \)
      "  let dashdistance = float2nr(g:sluice_pixel_density / (1.0*a:options['iconwidth'])) / 2
      "  call a:vals['gutterImage'].placeRectangle(a:options['iconcolor'],
      "        \a:vals['lines'][line]['modulo']+g:sluice_pixel_density*(a:vals['lines'][line]['signLine']-1),
      "        \a:options['iconwidth'],
      "        \a:vals['pixelsperline'],a:options['iconalign'],
      "        \"fill-opacity:0.3; stroke-dasharray=\"". dashdistance .",". dashdistance ."\"",'rx="1" ry="1"')
      "  " TODO also make the text icon a couple of dots or something.
      "else
        "echom "---"
        "echom "    pd    ppl = ". g:sluice_pixel_density ." ". string(a:vals['pixelsperline'])
        "echom printf("group1 %d group0 %d + 1= %d", group[1],  group[0],(group[1]-group[0]+1))
        "echom "slin1  slin0  = ". a:vals['lines'][group[1]]['signLine'] ." ". a:vals['lines'][group[0]]['signLine']
        "echom printf("mod1 %d   mod0 %d = %d", a:vals['lines'][group[1]]['modulo'], a:vals['lines'][group[0]]['modulo'],
        "      \(a:vals['lines'][group[1]]['modulo']-
        "      \  a:vals['lines'][group[0]]['modulo'])
        "      \)
        call a:vals['gutterImage'].placeRectangle(a:options['iconcolor'],
              \a:vals['lines'][group[0]]['modulo']+g:sluice_pixel_density*(a:vals['lines'][group[0]]['signLine']-1),
              \a:options['iconwidth'],
              \float2nr(a:vals['pixelsperline']*(group[1]-group[0]+1)) +
              \(a:vals['lines'][group[1]]['modulo']-
              \a:vals['lines'][group[0]]['modulo']),
              \a:options['iconalign'],"fill-opacity:0.7;",'rx="1" ry="1"')
      "endif
    else
      " TODO do some default painting. a brick for the whole thing maybe.
    endif
	endfor
	return result
endfunction

" given a sorted list, return the groups of ranges (see test case)
function! sluice#renderers#util#groupNumbers(sorted)
  let ranges = []
  let curr = []
  for n in a:sorted
    let n = str2nr(n)
    if len(curr) == 0
      let curr = [n,n]
    elseif curr[1]+1 == n
      let curr[1] = n
    else
      let ranges = add(ranges,curr)
      let curr = [n,n]
    endif
  endfor
  if len(curr) != 0 && (len(ranges) == 0 || curr[1] != ranges[len(ranges)-1][1])
    let ranges = add(ranges,curr)
  endif
  return ranges
endfunction
