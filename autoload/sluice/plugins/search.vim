" Search plugin. When you search for anything that ends up in the @/ register,
" this plugin will display the search location in the gutter.
"
" Options:
"  max_searches: Maximum number of forward and backward searches to performed.
"                Smaller numbers will make this a more efficient plugin (but 
"                won't show all matches in the gutter). (default: 25)
"
" Colors:
"    Colors for the render will automatically be selected for
"    color/xcolor/iconcolor if none are provided in the options. The colors
"    will be selected to relate to the 'Search' highlight group.

function! sluice#plugins#search#init(options)
  if !has_key(a:options,'max_searches')
    let a:options['max_searches'] = 25
  endif
  if !has_key(a:options,'color')
    let a:options['color'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
  if !has_key(a:options,'xcolor')
    let a:options['xcolor'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
  if !has_key(a:options,'iconcolor')
    let a:options['iconcolor'] = sluice#plugins#undercursor#getcolor('guifg','Search')
  endif
endfunction

function! sluice#plugins#search#deinit()
endfunction

function! sluice#plugins#search#data(options)
  let opts = copy(a:options)
  " when in not in macro mode, we want to search everything only within our
  " current page range.
  if !sluice#renderer#getmacromode()
    if has_key(opts,'max_searches')
      unlet opts.max_searches
    endif
    let dims = sluice#util#location#getwindowdimensions({})
    let opts.upmax = dims.pos - dims.top + 1
    let opts.downmax = dims.bottom - dims.pos + 1
  endif
  if !exists('b:sluice_searchfn')
    let b:sluice_searchfn = _#memoize(
          \function('sluice#plugins#search#search'),
          \function('sluice#plugins#search#memoizeByLocAndFileVer'))
  endif
  " if the # of memoized values gets big maybe purge...
  "if b:sluice_searchfn.data['misses'] > 50
  "  b:sluice_searchfn.clear()
  "endif
  return b:sluice_searchfn.call(opts)
endfunction

" TODO add a max timeout function to this method...this would then require
" some kind of...'resume' functionality... get rid of the 'max searches'
" completely
"
" Use reltime() to get the start time. Says its system dependend but it
" appears to be seconds and ... milliseconds.
"
" TODO add a paramter to this for max time...
"
" Parameters:
"   options: Several keys can be included to change this search method...
"     max_searches - Limits total number of results upward or
"                    downward. Defaults to 50.
"     needle       - search pattern. If not specified, @/ is used.
"     upmax        - max lines upward.
"     downmax      - max lines upward.
" TODO min line, max line for 'micro' mode searches
" 
" Returns: A hash is returned with the following keys:
"   'lines' - A hash of lines
"     'count' - number of matches on the line. TODO remove the count, and
"     optimize to move on from the line after matching it.
"   'upmax'   - True if the 'max_searches' is reached (potentially more
"               matches) in the upward direction.
"   'downmax' - True if the 'max_searches' is reached downward.
"
" SideAffects: The 'options' parameter  ... should not be modified...
function! sluice#plugins#search#search(options)
  " max number of milliseconds
  "let maxtime = 500
  "let starttime = reltime()
  "" there just isn't a way to do this quickly at this point:
  "if maxtime < 50
  "  return {}
  "endif

  " set the search pattern
  if has_key(a:options,'needle')
    let pattern = a:options['needle']
  else
    let pattern = @/
  endif

  if !has_key(a:options,'max_searches')
    let a:options['max_searches'] = 50
  endif

  if !has_key(a:options,'upmax') && has_key(a:options,'downmax')
    throw "'upmax' must be provided when 'downmax' is provided."
  endif

  if has_key(a:options,'upmax') && !has_key(a:options,'downmax')
    throw "'downmax' must be provided when 'upmax' is provided."
  endif

  let results = {}
  let results['lines'] = {}

	let n = 0
	let startLine = line('.')
	exe "keepjumps ". startLine
	let searchResults = {}

	" TODO I should do 'c' option as well, but it requires some cursor moving
	" to ensure no infinite loops
  try
    let here = search(pattern,"We")
    " search downward direction
    while len(pattern) > 0 && here > 0
      " max searches break out
      if n >= a:options['max_searches']
        break
      endif
      if has_key(a:options,'downmax') && here >= startLine + a:options['downmax']
        break
      endif
      " downmax breakout
      " 99% of the time the key isn't there yet, so minimize time there.
      if has_key(results['lines'],here)
        let results['lines'][here]['count'] += 1
      else
        let results['lines'][here] = {}
        let results['lines'][here]['count'] = 1
      endif
      let n += 1
      let here = search(pattern,"We")
    endwhile
    let results['downmax'] = here > 0 && n == a:options['max_searches']
  catch /.*/
    let results['downmax'] = 0
  endtry
	exe "keepjumps ". startLine
	let n = 0
  try
    let here = search(pattern,"Wb")
    " search upwards
    while len(pattern) > 0 && here > 0
      if n >= a:options['max_searches']
        break
      endif
      if has_key(a:options,'upmax') && here <= startLine - a:options['upmax']
        break
      endif
      " 99% of the time the key isn't there yet, so minimize time there.
      if has_key(results['lines'],here)
        let results['lines'][here]['count'] += 1
      else
        let results['lines'][here] = {}
        let results['lines'][here]['count'] = 1
      endif
      let n += 1
      let here = search(pattern,"Wb")
    endwhile
    let results['upmax'] = here > 0 && n == a:options['max_searches']
  catch /.*/
    let results['upmax'] = 0
  endtry
	exe "keepjumps ". startLine
	return results
endfunction

function! sluice#plugins#search#enabled(options)
  return 1
endfunction

" A memoization function for the _#memoize
" function.
" Memoizes by the current window dimensions, and the changedtick (version of
" file)
function! sluice#plugins#search#memoizeByLocAndFileVer(args)
  let options = a:args[0]

  if has_key(options,'needle')
    let pattern = options['needle']
  else
    let pattern = @/
  endif

  " TODO check that the previous line is within some wiggle of the current
  " line...and that changedtick hasn't changed.
  return _#hash(printf("%s-%s-%s",
        \b:changedtick,
        \line('.'),
        \pattern
        \))
endfunction
