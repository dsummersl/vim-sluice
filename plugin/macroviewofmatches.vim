" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" ie, MarkSearch("Something","green", "*")
"function! MarkSearch(search,color="auto",character='*')
"endfunction
"function! MarkClearAll()
"endfunction
"
" TODO git plugin for additions and subtractions
" TODO a gundo compatible plugin - it shows you where you've been making
" changes (colors boldly the recent changes).
" TODO a plugin that shows you where the other match for the keyword that
" you'veplaced your keyboard on is located (and use the matchit plugin if it
" esists for for/endfor/etc).
"
" NEXT:
" - Seamlessly work on console or GUI mode.
" New implementations:
" - data sources (that can pretty much stay as is.
"     - stateless
" - Signs: a wrapper around the gutter implementation (point to cache what is
"   currently there.
"     - state (tie to window)
" - MacroSigns: a wrapper around the gutter implementation that only paints on
"   the signs in the current viewpoint.
"     - state (tie to window)
" - Window: encapsulate the entire state of the current window (size,
"   location?)
"     - state (tie to window)
" - Painter (takes Signs or MacroSigns):
"     - stateless


" mappings"{{{

" Sanity checks
if has( "signs" ) == 0 || has("float") == 0 || v:version/100 < 7
	echohl ErrorMsg
	echo "MacroViewOfMatches requires Vim to have +signs and +float support and Vim v7+"
	echohl None
	finish
endif

au! CursorHold * nested call mvom#renderer#RePaintMatches()

" Toggle the status of MVOM in the current buffer:
command! -bar MVOMtoggle call mvom#renderer#setenabled(!mvom#renderer#getenabled())

" Enable the status of MVOM in the current buffer:
command! -bar MVOMenable call mvom#renderer#setenabled(1)

" Disable the status of MVOM in the current buffer:
command! -bar MVOMdisable call mvom#renderer#setenabled(0)

"}}}
" Private Variables "{{{
if !exists('w:mvom_lastcalldisabled') | let w:mvom_lastcalldisabled=1 | endif
"}}}
" Default Configuration"{{{
" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=200

" default background color of the gutter:
" if unset, then use the background of the existing window
if !exists('g:mvom_default_bg') | let g:mvom_default_bg = 'dddddd' | endif
exe "autocmd BufNewFile,BufRead * highlight! SignColumn guifg=white guibg=#". g:mvom_default_bg

" Enable any not ready for primetime features?
if !exists('g:mvom_alpha') | let g:mvom_alpha=1 | endif

" Global variable to enable/disable MVOM
if !exists('g:mvom_enabled') | let g:mvom_enabled=1 | endif

" Global variable to enable/disable MVOM by default when opening files.
if !exists('g:mvom_default_enabled') | let g:mvom_default_enabled=0 | endif

" Where icons are stored (by default, where the MVOM plugin is located).
if !exists('g:mvom_cache') | let g:mvom_icon_cache=substitute(expand('<sfile>'),"\\v\/[^\/]+$","","") .'/mvom-cache/' | endif
exec "silent ! mkdir -p ". g:mvom_icon_cache

if !exists('g:mvom_loaded')
	" Setup the type of plugins you want:
	" Show the last search with //
	call mvom#renderer#add('mvom#plugins#search', {
				\ 'render': 'mvom#renderers#slash',
				\ 'chars': '/ ',
				\ 'color': '0055ff',
				\ 'xchars': 'X ',
				\ 'iconcolor': '0055ff',
				\ 'iconalign': 'left',
				\ 'iconwidth': 50,
				\ 'xcolor': '0055ff'
				\ })
	" Show all keywords in the file that match whats under your cursor with \\
	call mvom#renderer#add('mvom#plugins#undercursor', {
				\ 'render': 'mvom#renderers#slash',
				\ 'chars': '\ ',
				\ 'color': 'b5f1ff',
				\ 'xchars': 'X ',
				\ 'xcolor': '0055ff',
				\ 'iconcolor': 'cceecc',
				\ 'iconalign': 'right',
				\ 'iconwidth': 50,
				\ 'bg': 'e5f1ff',
				\ 'fg': '000000'
				\ })
	" Show the visible portion with a darker background
	call mvom#renderer#add('mvom#plugins#window', {
	      \ 'render': 'mvom#renderers#background',
	      \ 'bg': 'dddddd',
	      \ 'iconcolor': 'dddddd',
	      \ 'iconalign': 'left',
	      \ 'iconwidth': 10,
	      \ 'showinline': 1
	      \ })
	let g:mvom_loaded = 1
endif
"}}}
" vim: set fdm=marker noet:
