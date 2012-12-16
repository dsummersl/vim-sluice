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
	"echom "bg init". reltime()[0]
endfunction

function! mvom#renderers#background#paint(options,vals)
	"echom "bg paint". reltime()[0]
  if has_key(a:options,'showinline')
    let showinline = a:options['showinline']
  else
    let showinline = 0
  endif
	let result = {}
	let bgcolor = a:options['bg']
	let modded = mvom#util#color#RGBToHSV(mvom#util#color#HexToRGB(bgcolor))
	" TODO if the bg is dark this code doesn't really color correctly (needs to
	" change by more and by something fixed I think
	if modded[2] > 50 " if its really light, lets darken, otherwise we'll lighten
		let modded[2] = float2nr(modded[2]*0.9)
	else
		let modded[2] = float2nr(modded[2]+modded[2]*0.1)
	endif
	let bgcolor = mvom#util#color#RGBToHex(mvom#util#color#HSVToRGB(modded))
	for line in keys(a:vals)
		let color = bgcolor
		if has_key(a:vals[line],'iscurrentline') && showinline
			let darkened = mvom#util#color#RGBToHSV(mvom#util#color#HexToRGB(bgcolor))
			let darkened[2] = float2nr(darkened[2]*0.9)
			let color = mvom#util#color#RGBToHex(mvom#util#color#HSVToRGB(darkened))
		endif
		if has_key(a:vals[line],'text')
			let result[line] = { 'bg':color }
		else
			let result[line] = { 'bg':color }
		endif
	endfor
	return result
endfunction

function! mvom#renderers#background#reconcile(options,vals)
	"echom "bg reconcile". reltime()[0]
	return a:vals
endfunction
