function! sluice#renderers#util#FindPlugin(dataPlugin)
  for plugin in g:mv_plugins
    if plugin['name'] == a:dataPlugin
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
" Parameters:
"   vals   : Dictionary of lines. Keys:
"     'lines': Dictionary of line numbers. The presence of the line number is
"              all that is needed.
"     'upmax': TODO hint to show that there could be more matches upwards
"     'downmax': TODO hint to show that there could be more matches downwards
"     'color': TODO if there is a color here, then override?
"     
"   options: Required values for this dictionary:
"     'color': The foreground color
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
          \max['line'] == line
      let max = copy(a:vals['lines'][line])
      let max['line'] = line
    endif
    if !has_key(min,'line') ||
          \min['line'] > line ||
          \min['line'] == line
      let min = copy(a:vals['lines'][line])
      let min['line'] = line
    endif
  endfor

  " place all the normal text chars an dcolors:
  for line in keys(a:vals['lines'])
    let result['lines'][line] = { 'text': a:options['chars'], 'fg': a:options['color'], 'bg': defaultbg }
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
