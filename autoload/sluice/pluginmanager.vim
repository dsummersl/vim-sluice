" Get a list of plugin names for completion functions in the command definitions
" in sluice.vim
function! sluice#pluginmanager#getnames(A,L,P)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
  let result = []
  for plugin in g:mv_plugins
    " window is builtin and shouldn't be visible to the user.
    if plugin['name'] != 'window'
      call add(result,plugin['name'])
    endif
  endfor
	return result
endfunction

" Configuration and enable/disable functions
" Add a specific plugin and rendering.
"
" Parameters:
"     name The name of the plugin (human readablo, succinct)
"     options    Options for the plugin. Depends on the plugin, but all
"                plugins have the following options:
"
"                    data   : Path to this plugin's data source (git, underscore,
"                             etc)
"                    render : Path to the renderer type.
"                    enabled: boolean (0, or 1) that allows the plugin to be
"                             turned off/on.
"
function! sluice#pluginmanager#add(pluginName,options)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	let old_enabled=g:sluice_enabled
	let g:sluice_enabled=0
  let a:options["enabled"] = 1
	call {a:options['data']}#init(a:options)
	call add(g:mv_plugins,{ 'name': a:pluginName, 'options': a:options })
	let g:sluice_enabled=old_enabled
endfunction

" Remove a plugin.
function! sluice#pluginmanager#remove(pluginName)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
	let old_enabled=g:sluice_enabled
	let g:sluice_enabled=0
  let options = sluice#renderers#util#FindPlugin(a:pluginName)['options']
	call {options['data']}#deinit()
  let cnt = -1
  for p in g:mv_plugins
    let cnt = cnt + 1
    if p['name'] == a:pluginName
      break
    endif
  endfor
  if cnt >= 0
    call remove(g:mv_plugins,cnt)
  endif
	let g:sluice_enabled=old_enabled
endfunction

" Set a plugin option. See the related plugin documentation
" for what options are available.
function! sluice#pluginmanager#setoption(pluginName,option,value)
  let options = sluice#renderers#util#FindPlugin(a:pluginName)['options']
  let options[a:option] = a:value
endfunction

function! sluice#pluginmanager#setenabled(pluginName,enabled)
  call sluice#pluginmanager#setoption(a:pluginName,'enabled',a:enabled)
  call sluice#renderer#RePaintMatches()
endfunction

function! sluice#pluginmanager#getenabled(pluginName)
	if !exists('g:mv_plugins') | let g:mv_plugins = [] | endif
  let plugin = sluice#renderers#util#FindPlugin(a:pluginName)
  if type(plugin) == 0
    return 0
  endif
  return plugin['options']['enabled']
endfunction

function! sluice#pluginmanager#toggle(pluginName)
  call sluice#pluginmanager#setenabled(a:pluginName,!sluice#pluginmanager#getenabled(a:pluginName))
endfunction

" vim: set fdm=marker:
