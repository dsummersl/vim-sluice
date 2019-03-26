
function! sluice#util#color#GetHighlightName(dictionary)
	return "Sluice_".a:dictionary['fg'].a:dictionary['bg']
endfunction

" Convert a 6 character hex RGB to a 3 part (0-255) array.
function! sluice#util#color#HexToRGB(hex)
	return ["0x".a:hex[0:1]+0,"0x".a:hex[2:3]+0,"0x".a:hex[4:5]+0]
endfunction

" Convert a 3 part (0-255) array to a 6 char hex equivalent.
function! sluice#util#color#RGBToHex(hex)
	return printf("%02x%02x%02x",a:hex[0],a:hex[1],a:hex[2])
endfunction

" Make an array of HSV values from an array to RGB values.
function! sluice#util#color#RGBToHSV(rgb)
	let two55 = trunc(255)
	let normd = copy(a:rgb)
	let normd[0] = a:rgb[0]/two55
	let normd[1] = a:rgb[1]/two55
	let normd[2] = a:rgb[2]/two55
	let mx = max(a:rgb)/two55
	let mn = min(a:rgb)/two55
	let hue = 0
	if mx == mn
		let hue = 0
	elseif normd[0] == mx
		let hue = float2nr(60*((normd[1]-normd[2])/trunc(mx-mn))+360) % 360
	elseif normd[1] == mx
		let hue = float2nr(60*((normd[2]-normd[0])/trunc(mx-mn))+120) % 360
	elseif normd[2] == mx
		let hue = float2nr(60*((normd[0]-normd[1])/trunc(mx-mn))+240) % 360
	endif
	if hue < 0
		let hue = 360 + hue
	endif
	let sat = 0
	if mx > 0
		if mn == mx || trunc(mx) == 0
			let sat = 0
		else
			let sat = 1-mn/trunc(mx)
		endif
	endif
	let val = mx
	return [float2nr(hue),float2nr(sat*100),float2nr(val*100)]
endfunction

function! sluice#util#color#HSVToRGB(hsv)
	let one00 = trunc(100)
	let normd = copy(a:hsv)
  if normd[1] > 100 | let normd[1] = 100 | endif
  if normd[2] > 100 | let normd[2] = 100 | endif
  if normd[1] < 0 | let normd[1] = 0 | endif
  if normd[2] < 0 | let normd[2] = 0 | endif
	let normd[1] = normd[1] / one00
	let normd[2] = normd[2] / one00
	let six0 = trunc(60)
	let hi = float2nr(floor(normd[0]/six0)) % 6
	let f = normd[0]/six0 - floor(normd[0]/six0)
	let p = normd[2]*(1-normd[1])
	let q = normd[2]*(1-f*normd[1])
	let t = normd[2]*(1-(1-f)*normd[1])
	let result = [0,0,0]
	if hi == 0
		let result = [normd[2],t,p]
	elseif hi == 1
		let result = [q,normd[2],p]
	elseif hi == 2
		let result = [p,normd[2],t]
	elseif hi == 3
		let result = [p,q,normd[2]]
	elseif hi == 4
		let result = [t,p,normd[2]]
	elseif hi == 5
		let result = [normd[2],p,q]
	endif
	let result[0] = float2nr(result[0]*255)
	let result[1] = float2nr(result[1]*255)
	let result[2] = float2nr(result[2]*255)
	return result
endfunction

function! sluice#util#color#darker(color)
	let modded = sluice#util#color#RGBToHSV(sluice#util#color#HexToRGB(a:color))
  let modded[2] = float2nr(modded[2] - 5)
	return sluice#util#color#RGBToHex(sluice#util#color#HSVToRGB(modded))
endfunction

function! sluice#util#color#lighter(color)
	let modded = sluice#util#color#RGBToHSV(sluice#util#color#HexToRGB(a:color))
  let modded[2] = float2nr(modded[2] + 5)
	return sluice#util#color#RGBToHex(sluice#util#color#HSVToRGB(modded))
endfunction

" Get the non-current window background color
function! sluice#util#color#get_default_bg()
  " If there is no default bg, get the current background and then either make
  " it darker or lighter depending on the current color scheme.
  if g:sluice_default_bg == ''
    let bg = sluice#util#color#getbg()
    if &background == 'dark'
      let bg = sluice#util#color#lighter(bg)
      let bg = sluice#util#color#lighter(bg)
    else
      let bg = sluice#util#color#darker(bg)
      let bg = sluice#util#color#darker(bg)
    endif
  else
    let bg = g:sluice_default_bg
  endif
  return bg
endfunction

" Get the normal background color
"
" Returns: color of highlight.
function! sluice#util#color#getbg()
  return sluice#util#color#getcolor('guibg','Normal')
endfunction

" Get a color from a highlight group.
"
" If the part doesn't exist return's 0 (false).
function! sluice#util#color#getcolor(part,hi)
  let currenthi=''
  redir => currenthi
  exe "silent! highlight ". a:hi
  redir END

  " try to pull out a hex color code:
  for line in split(currenthi,'\n')
    for part in split(line,' ')
      let ab = split(part,'=')
      if len(ab) == 2 && ab[0] == a:part
	if ab[1] =~ '^#\v\x{6}$'
	  return substitute(ab[1],'^#','','')
	else
	  try
	    let rgbmap = csapprox#rgb()
	    if has_key(rgbmap,tolower(ab[1]))
	      " remove any hex/# from the front of the string.
	      return substitute(
		    \substitute(rgbmap[tolower(ab[1])],'^0x','','')
		    \,'^#','','')
	    else
	      " no key, just return the value
	      return ab[1]
	    endif
	  catch
	    " do nothing, we probably don't have csapprox#rgb
	  endtry
	endif
      endif
    endfor
  endfor

  return 0
endfunction
