" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" TODO a quicklist plugin.
" TODO git plugin for additions and subtractions
" TODO a gundo compatible plugin - it shows you where you've been making
" changes (colors boldly the recent changes).
" TODO a plugin that shows you where the other match for the keyword that
" you'veplaced your keyboard on is located (and use the matchit plugin if it
" esists for for/endfor/etc).

" Dependency check:"{{{
if !has("python") || !has("signs") || !has("float") || v:version/100 < 7
	let g:sluice_enabled = 0
	echohl ErrorMsg
	echo "Sluice requires Vim 7+ to have +signs, +float, and +python."
	echohl None
	finish
endif
"}}}
" Default Configuration"{{{

" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=200

" default background color of the gutter (ie, 'eeeeee'):
" if unset, then use the background of the existing window
if !exists('g:sluice_default_bg') | let g:sluice_default_bg = '' | endif

" Global variable to enable/disable Sluice
if !exists('g:sluice_enabled') | let g:sluice_enabled=1 | endif

" Global variable to enable/disable Sluice by default when opening files.
if !exists('g:sluice_default_enabled') | let g:sluice_default_enabled=0 | endif

" Global variable for default macro/non-macro mode.
if !exists('g:sluice_default_macromode') | let g:sluice_default_macromode=0 | endif

" Global to enable graphical icons
if !exists('g:sluice_graphics_enabled') | let g:sluice_graphics_enabled=0 | endif

" ImageMagick 'convert' command location
if !exists('g:sluice_convert_command') | let g:sluice_convert_command='convert' | endif

if !exists('g:sluice_pixel_density') | let g:sluice_pixel_density=10 | endif

if !exists('g:sluice_loaded')
	" Setup the type of plugins you want:
	" Show the visible portion with a darker background
	call sluice#renderer#add('sluice#plugins#window', {
	      \ 'render': 'sluice#renderers#background',
	      \ 'iconcolor': 'dddddd',
	      \ 'iconalign': 'left',
	      \ 'iconwidth': 10,
	      \ 'showinline': 1
	      \ })
	"
	" TODO when not in 'macro' mode we only need to search the contents of the
	" on screen lines.
	"
	" TODO for the search plugin define the colors by the HighLight group if its
	" undefined. Same for undercursor, but make it transparent?
	"
	" Show the last search with //
	call sluice#renderer#add('sluice#plugins#search', {
				\ 'render': 'sluice#renderers#slash',
				\ 'chars': '/ ',
				\ 'color': '0055ff',
				\ 'xchars': 'X ',
				\ 'xcolor': '0055ff',
				\ 'iconcolor': '0055ff',
				\ 'iconalign': 'center',
				\ 'iconwidth': 100,
				\ 'max_searches': 25
				\ })
	" Show all keywords in the file that match whats under your cursor with \\
	call sluice#renderer#add('sluice#plugins#undercursor', {
				\ 'render': 'sluice#renderers#slash',
				\ 'chars': '\ ',
				\ 'color': '586ca3',
				\ 'xchars': 'X ',
				\ 'xcolor': '586ca3',
				\ 'iconcolor': '586ca3',
				\ 'iconalign': 'right',
				\ 'iconwidth': 60,
				\ 'max_searches': 10
				\ })
	" Show all git changes with +/- icons.
	call sluice#renderer#add('sluice#plugins#git', {
	      \ 'gitcommand': 'git',
	      \ 'render': 'sluice#plugins#git',
				\ 'addedcolor': '00bb00',
				\ 'addedchar': '+',
				\ 'removedcolor': 'bb0000',
				\ 'removedchar': '-',
	      \ 'iconalign': 'right',
	      \ 'iconwidth': 20
	      \ })
	let g:sluice_loaded = 1
endif
"}}}
" mappings"{{{

au! CursorHold * nested call sluice#renderer#RePaintMatches()

" Toggle the status of Sluice in the current buffer:
command! -bar SluiceToggle call sluice#renderer#setenabled(!sluice#renderer#getenabled())

" Enable the status of Sluice in the current buffer:
command! -bar SluiceEnable call sluice#renderer#setenabled(1)

" Disable the status of Sluice in the current buffer:
command! -bar SluiceDisable call sluice#renderer#setenabled(0)

" Toggle the macro/micro mode gutter
command! -bar SluiceMacroToggle call sluice#renderer#setmacromode(!sluice#renderer#getmacromode())

" Turn on micro mode gutter
command! -bar SluiceMacroOff call sluice#renderer#setmacromode(0)

" Turn on macro mode gutter
command! -bar SluiceMacroOn call sluice#renderer#setmacromode(1)

"}}}
" Private Variables "{{{

if !exists('w:sluice_lastcalldisabled') | let w:sluice_lastcalldisabled=1 | endif

if !exists('g:sluice_cache') | let g:sluice_icon_cache=substitute(expand('<sfile>'),"\\v\/[^\/]+$","","") .'/sluice-cache/' | endif

" Check to see if GUI mode is on, and we can find the 'convert' function. If
" not, turn it off.
let g:sluice_imagemagic_supported = 0
if has("gui_running") && g:sluice_graphics_enabled
	exe "silent !". g:sluice_convert_command ." -version"
	if !v:shell_error
		let g:sluice_imagemagic_supported = 1
		exec "silent ! mkdir -p ". g:sluice_icon_cache
		echohl ErrorMsg
		echo "Imagemagick 'convert' command not found. Graphic icons disabled."
		echohl None
	else
	endif
endif

"}}}
" vim: set fdm=marker noet:
