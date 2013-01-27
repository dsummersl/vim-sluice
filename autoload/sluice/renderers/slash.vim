" Slash (//) painter
"
" Options:
"   chars  : characters to display on a match. Must be two characters long.
"   color  : optional - Color of characters. If not set, hl-Search is used.
"   xchars : characters to display on a conflict with another plugin. Must be
"            two characters long.
"   xcolor : optional - Color of xchars. If not set, hl-Search is used.

function! sluice#renderers#slash#paint(options,vals)
  if !has_key(a:options,'color')
    let a:options['color'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
  if !has_key(a:options,'xcolor')
    let a:options['xcolor'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
  if !has_key(a:options,'iconcolor')
    let a:options['iconcolor'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
	return sluice#renderers#util#TypicalPaint(a:vals,a:options)
endfunction

function! sluice#renderers#slash#reconcile(options,vals,plugin)
  " TODO Modify the original slash reconcile so that it combines the 'chars'
  " together...so in the case of git it'd create '\+' or '\-'
  let result = {}
	let slashconflict = 0
	for p in a:vals
    " TODO crappy dependency on a global ...
    let render = sluice#renderers#util#FindRenderForPlugin(p['plugin'])
    let plugin = sluice#renderers#util#FindPlugin(p['plugin'])
		if render == 'sluice#renderers#slash' && plugin['options']['chars'] != a:options['chars']
			let slashconflict = 1
      if match(a:options['xchars'],' [^ ]') >= 0
        " when the conflict characters are just the first character, then just put
        " the second in there with whatever was in the first.
        let result['text'] = strpart(a:options['xchars'],1,1) .
              \strpart(plugin['options']['chars'],0,1)
      elseif match(a:options['xchars'],'[^ ] ') >= 0
        " when the conflict characters are just the second, then just put
        " the second in there with whatever was in the first.
        let result['text'] = strpart(a:options['xchars'],0,1) .
              \strpart(plugin['options']['chars'],1,1)
      else
        let result['text'] = a:options['xchars']
      endif
      let result['fg'] = a:options['xcolor']
		endif
	endfor
	if !slashconflict
    let result['text'] = a:options['chars']
    let result['fg'] = a:options['color']
	end
	return result
endfunction
