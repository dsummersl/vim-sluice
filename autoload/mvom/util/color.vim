function! mvom#util#color#GetHighlightName(dictionary)
	return "MVOM_".a:dictionary['fg'].a:dictionary['bg']
endfunction

function! mvom#util#color#GetSignName(dictionary)
	return mvom#util#color#GetHighlightName(a:dictionary)."_".mvom#util#location#GetHumanReadables(a:dictionary['text'])
endfunction

" Convert a 6 character hex RGB to a 3 part (0-255) array.
function! mvom#util#color#HexToRGB(hex)
	return ["0x".a:hex[0:1]+0,"0x".a:hex[2:3]+0,"0x".a:hex[4:5]+0]
endfunction

" Convert a 3 part (0-255) array to a 6 char hex equivalent.
function! mvom#util#color#RGBToHex(hex)
	return printf("%02x%02x%02x",a:hex[0],a:hex[1],a:hex[2])
endfunction

" Make an array of HSV values from an array to RGB values.
function! mvom#util#color#RGBToHSV(rgb)
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
		if mn == mx
			let sat = 0
		else
			let sat = 1-mn/trunc(mx)
		endif
	endif
	let val = mx
	return [float2nr(hue),float2nr(sat*100),float2nr(val*100)]
endfunction

function! mvom#util#color#HSVToRGB(hsv)
	let one00 = trunc(100)
	let normd = copy(a:hsv)
	let normd[0] = a:hsv[0]
	let normd[1] = a:hsv[1]/one00
	let normd[2] = a:hsv[2]/one00
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

" Return the unique elements in a list.
function! mvom#util#color#Uniq(list)
	let result = []
	for i in a:list
		if count(result,i) == 0
			call add(result,i)
		endif
	endfor
	return result
endfunction
