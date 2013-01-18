" Search plugin. When you search for anything that ends up in the @/ register,
" this plugin will display the search location in the gutter.
"
" Options:
"  max_searches: Maximum number of forward and backward searches to performed.
"                Smaller numbers will make this a more efficient plugin (but 
"                won't show all matches in the gutter). (default: 25)
"
"

function! mvom#plugins#search#init(options)
  if !has_key(a:options,'max_searches')
    let a:options['max_searches'] = 25
  endif
endfunction

function! mvom#plugins#search#deinit()
endfunction

function! mvom#plugins#search#data(options)
  if !exists('b:mvom_searchfn')
    let b:mvom_searchfn = mvom#util#location#memoize(
          \function('mvom#plugins#search#search'),
          \function('mvom#plugins#search#memoizeByLocAndFileVer'))
  endif
  " if the # of memoized values gets big maybe purge...
  "if b:mvom_searchfn.data['misses'] > 50
  "  b:mvom_searchfn.clear()
  "endif
  return b:mvom_searchfn.call(a:options)
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
"     'max_searches' - must be present. Limits total number of results. Can be
"                      up to double this value ('max up' and 'max down').
"     'needle'       - search pattern. If not specified, @/ is used.
" TODO min line, max line for 'micro' mode searches
" 
" Returns: A hash is returned with the following keys:
"   'lines' - A hash of lines
"     'count' - number of matches on the line.
"   'upmax'   - True if the 'max_searches' is reached (potentially more
"               matches) in the upward direction.
"   'downmax' - True if the 'max_searches' is reached downward.
"
" SideAffects: The 'options' parameter  ... should not be modified...
function! mvom#plugins#search#search(options)
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

  let results = {}
  let results['lines'] = {}

	let n = 0
	" TODO cache results so as to avoid researching on duplicates (save last
	" search and save state of file (if file changed or if search changed then
	" redo)
	let startLine = line('.')
	exe "keepjumps ". startLine
	let searchResults = {}
	" TODO I should do 'c' option as well, but it requires some cursor moving
	" to ensure no infinite loops
  try
    let here = search(pattern,"We")
    while len(pattern) > 0 && here > 0 && n < a:options['max_searches'] " search forwards
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
    while len(pattern) > 0 && here > 0 && n < a:options['max_searches'] " search backwards
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

function! mvom#plugins#search#enabled(options)
  return 1
endfunction

" A memoization function for the mvom#util#location#memoize
" function.
" Memoizes by the current window dimensions, and the changedtick (version of
" file)
function! mvom#plugins#search#memoizeByLocAndFileVer(args)
  let options = a:args[0]

  if has_key(options,'needle')
    let pattern = options['needle']
  else
    let pattern = @/
  endif

  " TODO check that the previous line is within some wiggle of the current
  " line...and that changedtick hasn't changed.
  return mvom#util#color#hash(printf("%s-%s-%s",
        \b:changedtick,
        \line('.'),
        \pattern
        \))
endfunction
