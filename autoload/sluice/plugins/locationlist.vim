" Locationlist: show matches entries in the location list.
"
" Supports the following colors:
"
"   errcolor:

function! sluice#plugins#locationlist#enabled(options)
  return 1
endfunction

function! sluice#plugins#locationlist#init(options)
  if !has_key(a:options,'errcolor')
    let a:options['errcolor'] = sluice#util#color#getcolor('guifg','ErrorMsg')
  endif
  if !has_key(a:options,'warncolor')
    let a:options['warncolor'] = sluice#util#color#getcolor('guifg','WarnMsg')
  endif
  if !has_key(a:options,'color')
    let a:options['color'] = sluice#util#color#getcolor('guifg','Search')
  endif
endfunction

function! sluice#plugins#locationlist#deinit()
  call sluice#plugins#search#deinit()
endfunction

" TODO memoize by this:
" function! sluice#plugins#search#memoizeByLocAndFileVer(args)

function! sluice#plugins#locationlist#data(options)
  let results = {}
  let results['lines'] = {}
  for entry in getloclist(winnr())
    let lineOptions = {}
    if entry['type'] == 'E'
      let lineOptions['color'] = a:options['errcolor']
    elseif entry['type'] == 'W'
      let lineOptions['color'] = a:options['warncolor']
    else
      let lineOptions['color'] = a:options['color']
    endif
    let results['lines'][string(entry['lnum'])] = lineOptions
  endfor
  return results
endfunction

