" Background options:
" showinline will show both the highlight both the areas that correspond to
" the current visible window, but also make the area where the cursor is
"
" Options:
"   showinline: If set, then make the location where the cursor is slightly
"               darker within the scrollbar area. Default: 1
"           bg: Background. If not set, then the current screen background
"               color is used.
"

function! sluice#renderers#background#paint(options,vals)
	"echom "bg paint". reltime()[0]
  let showinline = a:options['showinline']
	for line in keys(a:vals['lines'])
    let newbg = sluice#renderers#background#setBG(a:options,a:vals['lines'][line])
    let a:vals['lines'][line]['bg'] = newbg['bg']
	endfor

  try
    " select the min/max/current values from all the lines and then use that
    " to paint the gutter with just two elements:
    let mn = _#min(a:vals['lines'],"str2float(val['signLine'] .'.'. val['modulo'])")
    let mx = _#max(a:vals['lines'],"str2float(val['signLine'] .'.'. val['modulo'])")
    let cl = _#min(a:vals['lines'],"val['line'] == ". line('.') ."? str2float(val['signLine'] .'.'. val['modulo']) : 100000")
    let minLine = a:vals['lines'][mn]
    let maxLine = a:vals['lines'][mx]
    let currentLine = a:vals['lines'][cl]
  catch /.*/
    " probably no elements
  endtry

  " paint two rectangles on the graphic. One is the main background, the other
  " is the 'highlighted' part.
  call a:vals['gutterImage'].addRectangle(
        \a:options['bg'],
        \0,
        \g:sluice_pixel_density*(minLine['signLine']-1) + minLine['modulo'],
        \g:sluice_pixel_density,
        \g:sluice_pixel_density*(maxLine['signLine']-minLine['signLine']+1) + maxLine['modulo'],
        \"",
        \''
        \)
  if showinline
    call a:vals['gutterImage'].addRectangle(
          \a:options['inlinebg'],
          \0,
          \g:sluice_pixel_density*(currentLine['signLine']-1) + currentLine['modulo'],
          \g:sluice_pixel_density,
          \float2nr(a:vals['pixelsperline']),
          \'',
          \''
          \)
  endif
	return a:vals
endfunction

function! sluice#renderers#background#setBG(options,line)
  if has_key(a:options,'showinline') && a:options['showinline']
    let showinline = 1
  else
    let showinline = 0
  endif
  if has_key(a:line,'iscurrentline') && showinline
    let bgcolor = a:options['inlinebg']
  else
    let bgcolor = a:options['bg']
  endif
  return {'bg': bgcolor}
endfunction

function! sluice#renderers#background#reconcile(options,vals,plugin)
  " override any bg color options with our own setting:
  return sluice#renderers#background#setBG(a:options,a:plugin)
endfunction
