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

" Dependency check:"{{{
if !has("python") || !has("signs") || !has("float") || v:version/100 < 7
	let g:mvom_enabled = 0
	echohl ErrorMsg
	echo "MVOM requires Vim 7+ to have +signs, +float, and +python."
	echohl None
	finish
endif
"}}}
" Default Configuration"{{{

" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=200

" default background color of the gutter (ie, 'eeeeee'):
" if unset, then use the background of the existing window
if !exists('g:mvom_default_bg') | let g:mvom_default_bg = '' | endif

" Global variable to enable/disable MVOM
if !exists('g:mvom_enabled') | let g:mvom_enabled=1 | endif

" Global variable to enable/disable MVOM by default when opening files.
if !exists('g:mvom_default_enabled') | let g:mvom_default_enabled=0 | endif

" Global variable for default macro/non-macro mode.
if !exists('g:mvom_default_macromode') | let g:mvom_default_macromode=0 | endif

" Global to enable graphical icons
if !exists('g:mvom_graphics_enabled') | let g:mvom_graphics_enabled=1 | endif

" ImageMagick 'convert' command location
if !exists('g:mvom_convert_command') | let g:mvom_convert_command='convert' | endif

if !exists('g:mvom_pixel_density') | let g:mvom_pixel_density=12 | endif

if !exists('g:mvom_loaded')
	" Setup the type of plugins you want:
	" Show the visible portion with a darker background
	call mvom#renderer#add('mvom#plugins#window', {
	      \ 'render': 'mvom#renderers#background',
	      \ 'iconcolor': 'dddddd',
	      \ 'iconalign': 'left',
	      \ 'iconwidth': 10,
	      \ 'showinline': 1
	      \ })
	" Show the last search with //
	call mvom#renderer#add('mvom#plugins#search', {
	      \ 'render': 'mvom#renderers#slash',
	      \ 'chars': '/ ',
	      \ 'color': '0055ff',
	      \ 'xchars': 'X ',
	      \ 'iconcolor': '0055ff',
	      \ 'iconalign': 'center',
	      \ 'iconwidth': 100,
	      \ 'xcolor': '0055ff'
	      \ })
	" Show all keywords in the file that match whats under your cursor with \\
	call mvom#renderer#add('mvom#plugins#undercursor', {
	      \ 'render': 'mvom#renderers#slash',
	      \ 'chars': '\ ',
	      \ 'color': '586ca3',
	      \ 'xchars': 'X ',
	      \ 'xcolor': '586ca3',
	      \ 'iconcolor': '586ca3',
	      \ 'iconalign': 'right',
	      \ 'iconwidth': 60
	      \ })
	let g:mvom_loaded = 1
endif
"}}}
" mappings"{{{

au! CursorHold * nested call mvom#renderer#RePaintMatches()

" Toggle the status of MVOM in the current buffer:
command! -bar MVOMtoggle call mvom#renderer#setenabled(!mvom#renderer#getenabled())

" Enable the status of MVOM in the current buffer:
command! -bar MVOMenable call mvom#renderer#setenabled(1)

" Disable the status of MVOM in the current buffer:
command! -bar MVOMdisable call mvom#renderer#setenabled(0)

" Toggle the macro/micro mode gutter
command! -bar MVOMmacroToggle call mvom#renderer#setmacromode(!mvom#renderer#getmacromode())

" Turn on micro mode gutter
command! -bar MVOMmacroOff call mvom#renderer#setmacromode(0)

" Turn on macro mode gutter
command! -bar MVOMmacroOn call mvom#renderer#setmacromode(1)

"}}}
" Private Variables "{{{

if !exists('w:mvom_lastcalldisabled') | let w:mvom_lastcalldisabled=1 | endif

if !exists('g:mvom_cache') | let g:mvom_icon_cache=substitute(expand('<sfile>'),"\\v\/[^\/]+$","","") .'/mvom-cache/' | endif

" Check to see if GUI mode is on, and we can find the 'convert' function. If
" not, turn it off.
let g:mvom_imagemagic_supported = 0
if has("gui_running") && g:mvom_graphics_enabled
	exe "silent !". g:mvom_convert_command ." -version"
	if !v:shell_error
		let g:mvom_imagemagic_supported = 1
		exec "silent ! mkdir -p ". g:mvom_icon_cache
		echohl ErrorMsg
		echo "MVOM imagemagick 'convert' command not found. Graphic icons disabled."
		echohl None
	else
	endif
endif

"}}}
" vim: set fdm=marker noet:
