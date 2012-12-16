" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" ie, MarkSearch("Something","green", "*")
"function! MarkSearch(search,color="auto",character='*')
"endfunction
"function! MarkClearAll()
"endfunction
"
" TODO add a plugin that shows you the other matches if they are off screen.
" TODO I might want to not show search/undercursor/etc if they are onscreen
" (less clutter).
" TODO git plugin for additions and subtractions
" TODO a gundo compatible plugin - it shows you where you've been making
" changes (colors boldly the recent changes).
" TODO a status line to easily move/switch between the different plugins
"
" For icon support:
" 	- requires imagemagick to convert between xpm and png.
" 	- Make a new 'dash renderer' that has hte following options...:

" mappings"{{{

" Sanity checks
if has( "signs" ) == 0 || has("float") == 0 || v:version/100 < 7
	echohl ErrorMsg
	echo "MacroViewOfMatches requires Vim to have +signs and +float support and Vim v7+"
	echohl None
	finish
endif

au! CursorHold * nested call mvom#renderer#RePaintMatches()
"}}}
" Private Variables "{{{
if !exists('w:mvom_lastcalldisabled') | let w:mvom_lastcalldisabled=1 | endif
"}}}
" Default Configuration"{{{
" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=100

" default background color of the gutter:
if !exists('g:mvom_default_bg') | let g:mvom_default_bg = 'dddddd' | endif
exe "autocmd BufNewFile,BufRead * highlight! SignColumn guifg=white guibg=#". g:mvom_default_bg

" UnderCursor options:
" TODO ideally I'd read the hl-IncSearch colors (but I don't know quite how...)
"if !exists('g:mvom_undercursor_bg ') | let g:mvom_undercursor_bg ='e5f1ff' | endif
"if !exists('g:mvom_undercursor_fg ') | let g:mvom_undercursor_fg ='000000' | endif

if !exists('g:mvom_enabled') | let g:mvom_enabled=1 | endif
if !exists('g:mvom_loaded')
	" Setup the type of plugins you want:
	" Show the last search with //
	call mvom#renderer#add('mvom#plugins#search', {
				\ 'render': 'mvom#renderers#slash',
				\ 'chars': '/ ',
				\ 'color': '0055ff',
				\ 'xchars': 'X ',
				\ 'xcolor': '0055ff'
				\ })
	" Show all keywords in the file that match whats under your cursor with \\
	call mvom#renderer#add('mvom#plugins#undercursor', {
				\ 'render': 'mvom#renderers#slash',
				\ 'chars': '\ ',
				\ 'color': 'e5f1ff',
				\ 'xchars': 'X ',
				\ 'xcolor': '0055ff',
				\ 'fg': 'e5f1ff',
				\ 'bg': '000000',
				\ })
	" Show the visible portion with a darker background
	call mvom#renderer#add('mvom#plugins#window', {
	      \ 'render': 'mvom#renderers#background',
	      \ 'bg': 'dddddd',
	      \ 'showinline': 0
	      \ })
	let g:mvom_loaded = 1
endif
"}}}
" vim: set fdm=marker noet:
