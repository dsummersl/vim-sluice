function! mvom#plugins#search#init()
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
	while len(@/) > 0 && search(@/,"We") > 0 && n < g:mvom_max_searches " search forwards
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
	while len(@/) > 0 && search(@/,"Wb") > 0 && n < g:mvom_max_searches " search backwards
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
	return &hls == 1
endfunction
