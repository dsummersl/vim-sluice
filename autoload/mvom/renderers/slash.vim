" Slash (//) painter

function! mvom#renderers#slash#paint(options,vals)
	return mvom#renderers#util#TypicalPaint(a:vals,a:options)
endfunction

function! mvom#renderers#slash#reconcile(options,vals,plugin)
	let slashconflict = 0
	for p in a:vals
    let render = mvom#renderers#util#FindRenderForPlugin(p['plugin'])
    let plugin = mvom#renderers#util#FindPlugin(p['plugin'])
		if render == 'mvom#renderers#slash' && plugin['options']['chars'] != a:options['chars']
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
