" Slash (//) painter

function! sluice#renderers#slash#paint(options,vals)
	return sluice#renderers#util#TypicalPaint(a:vals,a:options)
endfunction

function! sluice#renderers#slash#reconcile(options,vals,plugin)
  " TODO Modify the original slash reconcile so that it combines the 'chars'
  " together...so in the case of git it'd create '\+' or '\-'
	let slashconflict = 0
	for p in a:vals
    " TODO crappy dependency on a global ...
    let render = sluice#renderers#util#FindRenderForPlugin(p['plugin'])
    let plugin = sluice#renderers#util#FindPlugin(p['plugin'])
		if render == 'sluice#renderers#slash' && plugin['options']['chars'] != a:options['chars']
			let slashconflict = 1
		endif
	endfor
  let result = {}
	if slashconflict
    let result['text'] = a:options['xchars']
    let result['fg'] = a:options['xcolor']
  else
    let result['text'] = a:options['chars']
    let result['fg'] = a:options['color']
	end
	return result
endfunction
