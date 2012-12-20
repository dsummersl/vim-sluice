" Search plugin. When you search for anything that ends up in the @/ register,
" this plugin will display the search location in the gutter.
"
" Options:
"   respect_hls: When this option is set to 1 this plugin will disable itself
"                if the hls setting is disabled. (default: 1)
"
"  max_searches: Maximum number of forward and backward searches to performed.
"                Smaller numbers will make this a more efficient plugin (but 
"                won't show all matches in the gutter). (default: 25)
"
"

function! mvom#plugins#search#init(options)
  if has_key(a:options,'respect_hls')
    let s:respect_hls=a:options['respect_hls']
  else
    let s:respect_hls=1
  end
  if has_key(a:options,'max_searches')
    let s:max_searches=a:options['max_searches']
  else
    let s:max_searches=25
  end
endfunction

function! mvom#plugins#search#deinit()
endfunction

" TODO add a max timeout function to this method...this would then require
" some kind of...'resume' functionality... get rid of the 'max searches'
" completely
"
" Use reltime() to get the start time. Says its system dependend but it
" apepars to be seconds and ... milliseconds.
"
" TODO add a paramter to this for max time...
function! mvom#plugins#search#data(options)
  " max number of milliseconds
  "let maxtime = 500
  "let starttime = reltime()
  "" there just isn't a way to do this quickly at this point:
  "if maxtime < 50
  "  return {}
  "endif

  " if the search is hte same and the palce is the same, return the previous
  " results
  if has_key(a:options,'previoussearch')
    " TODO check that the previous line is within some wiggle of the current
    " line...and that changedtick hasn't changed.
    if a:options['previoussearch'] == @/ && 
          \a:options['previousline'] < line('.') + s:max_searches &&
          \a:options['previousline'] > line('.') - s:max_searches &&
          \a:options['previoustick'] == b:changedtick
      return a:options['previousdata']
    endif
  endif

  " TODO this only needs to return NEW values if... @/ has changed, or the
  " cursor position has changed (or the file.

	" for this search make it match up and down a max # of times (performance fixing)
  "if exists('s:partialresults')
  "  let results = s:partialresults
  "else
  let results = {}
  "endif
  let a:options['previoustick'] = b:changedtick
  let a:options['previoussearch'] = @/
  let a:options['previousline'] = line('.')
	let n = 1
	let startLine = 1
	" TODO cache results so as to avoid researching on duplicates (save last
	" search and save state of file (if file changed or if search changed then
	" redo)
	let startLine = line('.')
	exe "". startLine
	let searchResults = {}
	" TODO I should do 'c' option as well, but it requires some cursor moving
	" to ensure no infinite loops
  let here = search(@/,"We")
	while len(@/) > 0 &&  here > 0 && n < s:max_searches " search forwards
    " 99% of the time the key isn't there yet, so minimize time there.
		if has_key(results,here)
      if has_key(results[here],'count')
        let cnt = results[here]['count']
        let cnt = cnt + 1
        let results[here]['count'] = cnt
      endif
		else
			let results[here] = {}
			let results[here]['count'] = 1
		endif
		let n = n+1
    let here = search(@/,"We")
	endwhile
	exe "". startLine
	let n = 1
  let here = search(@/,"Wb")
	while len(@/) > 0 && here > 0 && n < s:max_searches " search backwards
    " 99% of the time the key isn't there yet, so minimize time there.
		if has_key(results,here)
      if has_key(results[here],'count')
        let cnt = results[here]['count']
        let cnt = cnt + 1
        let results[here]['count'] = cnt
      endif
		else
			let results[here] = {}
			let results[here]['count'] = 1
		endif
		let n = n+1
    let here = search(@/,"Wb")
	endwhile
	exe "". startLine
  let a:options['previousdata'] = results
	return results
endfunction

function! mvom#plugins#search#enabled(options)
  if s:respect_hls == 1
    return &hls == 1
  endif
  return true
endfunction
