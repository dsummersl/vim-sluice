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

" Background Painter
function! mvom#renderers#background#init(options)
  if !has_key(a:options,'showinline')
    let a:options['showinline'] = 1
  endif
  if !has_key(a:options,'bg')
    let bg = mvom#plugins#undercursor#getbg()
    if &background == 'dark'
      " TODO possibly lighter X 2
      let bg = mvom#util#color#lighter(bg)
    else
      let bg = mvom#util#color#darker(bg)
    endif
    let a:options['bg'] = bg
  endif
endfunction

function! mvom#renderers#background#paint(options,vals)
	"echom "bg paint". reltime()[0]
  call mvom#renderers#background#init(a:options)
  let showinline = a:options['showinline']
	let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
	for line in keys(a:vals['lines'])
    let newbg = mvom#renderers#background#setBG(bgcolor,a:vals['lines'][line],showinline)
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
  let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
  call a:vals['gutterImage'].addRectangle(
        \bgcolor,
        \0,
        \g:mvom_pixel_density*(minLine['signLine']-1) + minLine['modulo'],
        \g:mvom_pixel_density,
        \g:mvom_pixel_density*(maxLine['signLine']-minLine['signLine']+1) + maxLine['modulo'],
        \"",
        \''
        \)
  if showinline
    let bgcolor = mvom#util#color#darker(bgcolor)
    call a:vals['gutterImage'].addRectangle(
          \mvom#renderers#background#makeBGColor(bgcolor),
          \0,
          \g:mvom_pixel_density*(currentLine['signLine']-1) + currentLine['modulo'],
          \g:mvom_pixel_density,
          \a:vals['pixelsperline'],
          \'',
          \''
          \)
  endif
	return a:vals
endfunction

function! mvom#renderers#background#makeBGColor(bgcolor)
	let modded = mvom#util#color#RGBToHSV(mvom#util#color#HexToRGB(a:bgcolor))
	" If the bg is dark this code doesn't really color correctly (needs to
	" change by more and by something fixed I think
	if modded[2] > 50 " if its really light, lets darken, otherwise we'll lighten
    return mvom#util#color#darker(a:bgcolor)
	else
    return mvom#util#color#lighter(a:bgcolor)
	endif
endfunction

function! mvom#renderers#background#setBG(bgcolor,line,showinline)
  if has_key(a:line,'iscurrentline') && a:showinline
    let bgcolor = mvom#util#color#darker(a:bgcolor)
  else
    let bgcolor = a:bgcolor
  endif
  return {'bg': bgcolor}
endfunction

function! mvom#renderers#background#reconcile(options,vals,plugin)
  " override any bg color options with our own setting:
  if has_key(a:options,'showinline') && a:options['showinline']
    let showinline = 1
  else
    let showinline = 0
  endif
	let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
  return mvom#renderers#background#setBG(bgcolor,a:plugin,showinline)
endfunction
