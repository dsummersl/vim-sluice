" Search plugin. When you search for anything that ends up in the @/ register,
" this plugin will display the search location in the gutter.
"
" Options:
"   g:mvom_search_respect_hls = 1|0 (default: 1)
"     When this option is set to 1 this plugin will disable itself if the hls
"     setting is disabled.
"
"   g:mvom_search_max_searches = # (default: 25)
"     Maximum number of forward and backward searches to performed. Smaller
"     numbers will make this a more efficient plugin (but won't show all
"     matches in the gutter).
"
"

if !exists('g:mvom_search_respect_hls') | let g:mvom_search_respect_hls = 1 | endif

" Maximum number of forward and backward searches to performed
if !exists('g:mvom_search_max_searches ') | let g:mvom_search_max_searches = 75 | endif


function! mvom#plugins#search#init(options)
endfunction

function! mvom#plugins#search#deinit()
endfunction

function! mvom#plugins#search#data()
	" for this search make it match up and down a max # of times (performance fixing)
	let results = {}
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
	while len(@/) > 0 && search(@/,"We") > 0 && n < g:mvom_search_max_searches " search forwards
		let here = line('.')
		let cnt = 0
		if has_key(results,here) && has_key(results[here],'count')
			let cnt = results[here]['count']
		else
			let results[here] = {}
		endif
		let cnt = cnt + 1
		let results[here]['count'] = cnt
		let n = n+1
	endwhile
	exe "". startLine
	let n = 1
	while len(@/) > 0 && search(@/,"Wb") > 0 && n < g:mvom_search_max_searches " search backwards
		let here = line('.')
		let cnt = 0
		if has_key(results,here) && has_key(results[here],'count')
			let cnt = results[here]['count']
		else
			let results[here] = {}
		endif
		let cnt = cnt + 1
		let results[here]['count'] = cnt
		let n = n+1
	endwhile
	exe "". startLine
	return results
endfunction

function! mvom#plugins#search#enabled()
  if g:mvom_search_respect_hls == 1
    return &hls == 1
  endif
  return true
endfunction
