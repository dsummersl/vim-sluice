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

  " paint to the image generator:
  let minLine = 0
  let maxLine = 0
  let currentLine = 0
	for line in keys(a:vals['lines'])
    let n = a:vals['lines'][line]['signLine']
    if has_key(a:vals['lines'][line],'iscurrentline')
      let currentLine = n
      if line('.') == line
        let currentModulo = a:vals['lines'][line]['modulo']
      endif
    endif
    if minLine == 0 || n < minLine
      let minLine = n
      if line('.') == line
        let minModulo = a:vals['lines'][line]['modulo']
      endif
    endif
    if maxLine == 0 || n > maxLine
      let maxLine = n
      if line('.') == line
        let maxModulo = a:vals['lines'][line]['modulo']
      endif
    endif
  endfor
  if !exists('currentModulo')
    let currentModulo = 0
  endif
  if !exists('maxModulo')
    let maxModulo = 0
  endif
  if !exists('minModulo')
    let minModulo = 0
  endif

  " paint two rectangles on the graphic. One is the main background, the other
  " is the 'highlighted' part.
  let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
  call a:vals['gutterImage'].addRectangle(
        \bgcolor,
        \0,
        \g:mvom_pixel_density*(minLine-1) + minModulo,
        \g:mvom_pixel_density,
        \g:mvom_pixel_density*(maxLine-minLine+1) + maxModulo,
        \"",
        \'rx="2" ry="2"'
        \)
  if showinline
    let bgcolor = mvom#util#color#darker(bgcolor)
    call a:vals['gutterImage'].addRectangle(
          \mvom#renderers#background#makeBGColor(bgcolor),
          \0,
          \g:mvom_pixel_density*(currentLine-1) + currentModulo,
          \g:mvom_pixel_density,
          \a:vals['pixelsperline'],
          \"",
          \'rx="2" ry="2"'
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
