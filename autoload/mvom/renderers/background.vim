" Background options:
" showinline will show both the highlight both the areas that correspond to
" the current visible window, but also make the area where the cursor is
"
" Options:
"   showinline: If set, then make the location where the cursor is slightly
"               darker within the scrollbar area. Default: 1
"           bg: background
"

" Background Painter
function! mvom#renderers#background#init(options)
endfunction

function! mvom#renderers#background#paint(options,vals)
	"echom "bg paint". reltime()[0]
  if has_key(a:options,'showinline') && a:options['showinline']
    let showinline = 1
  else
    let showinline = 0
  endif
	let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
	for line in keys(a:vals)
    let newbg = mvom#renderers#background#setBG(bgcolor,a:vals[line],showinline)
    let a:vals[line]['bg'] = newbg['bg']
	endfor
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

function! mvom#renderers#background#reconcile(options,vals)
  " override any bg color options with our own setting:
  if has_key(a:options,'showinline') && a:options['showinline']
    let showinline = 1
  else
    let showinline = 0
  endif
	let bgcolor = mvom#renderers#background#makeBGColor(a:options['bg'])
  return mvom#renderers#background#setBG(bgcolor,a:vals,showinline)
endfunction
