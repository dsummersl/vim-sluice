" This script is intended to use the +signs feature to show a high level list
" of matches to your current search. It gives you a general idea of all the
" areas in the file that match the search you performed.

" TODO a quicklist plugin.
" TODO a gundo compatible plugin - it shows you where you've been making
" changes (colors boldly the recent changes).
" TODO a plugin that shows you where the other match for the keyword that
" you'veplaced your keyboard on is located (and use the matchit plugin if it
" esists for for/endfor/etc).
" TODO show the region that is the current function that you are in (or maybe
" all functions). Consider this a bounty:
" http://stackoverflow.com/questions/14770596/display-line-number-per-function-in-vim
"
" TODO the git module breaks the control-^ control-6 function (alternate file).
" It just jumps to 'bb.txt'
"
" TODO Maybe use CursorMoved rather than the timer. This would include movements
" while text is selected - so you could see selected text in the gutter (and
" there would be no delay).

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

" default background color of the gutter (ie, 'eeeeee'):
" if unset, then use something slightly darker/lighter than the background.
if !exists('g:sluice_default_bg') | let g:sluice_default_bg = '' | endif

" Global variable to enable/disable Sluice
if !exists('g:sluice_enabled') | let g:sluice_enabled=1 | endif

" Global variable to enable/disable Sluice by default when opening files.
if !exists('g:sluice_default_enabled') | let g:sluice_default_enabled=0 | endif

" Global variable for default macro/non-macro mode.
if !exists('g:sluice_default_macromode') | let g:sluice_default_macromode=0 | endif

" TODO move into its renderer plugin
" Global to enable graphical icons
if !exists('g:sluice_graphics_enabled') | let g:sluice_graphics_enabled=1 | endif

" TODO move into its renderer plugin
" ImageMagick 'convert' command location
if !exists('g:sluice_convert_command') | let g:sluice_convert_command='convert' | endif

" TODO move into its renderer plugin
if !exists('g:sluice_pixel_density') | let g:sluice_pixel_density=20 | endif

if !exists('g:sluice_loaded')
	" Setup the type of plugins you want:
	"
	call sluice#pluginmanager#add('window', {
			\ 'data': 'sluice#plugins#window',
			\ 'render': 'sluice#renderers#background',
			\ 'iconalign': 'left',
			\ 'iconwidth': 10,
			\ 'showinline': 1
			\ })
	" Show the last search with //
	call sluice#pluginmanager#add('search', {
			\ 'data': 'sluice#plugins#search',
			\ 'render': 'sluice#renderers#slash',
			\ 'chars': '/ ',
			\ 'xchars': 'X ',
			\ 'xcolor': '0055ff',
			\ 'iconalign': 'center',
			\ 'iconwidth': 100,
			\ 'max_searches': 50
			\ })
	" Show all keywords in the file that match whats under your cursor with \\
	call sluice#pluginmanager#add('undercursor', {
			\ 'data': 'sluice#plugins#undercursor',
	    \ 'render': 'sluice#renderers#slash',
	    \ 'chars': '\ ',
	    \ 'xchars': 'X ',
	    \ 'xcolor': '0055ff',
	    \ 'iconalign': 'right',
	    \ 'iconwidth': 60,
	    \ 'max_searches': 10
	    \ })
	" Show all git changes with +/- icons.
	call sluice#pluginmanager#add('git', {
			\ 'data': 'sluice#plugins#git',
	    \ 'render': 'sluice#plugins#git',
	    \ 'gitcommand': 'git',
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

" Try to repaint on a regular basis:
autocmd! CursorHold * nested call sluice#renderer#RePaintMatches()
autocmd! TextChanged * nested call sluice#renderer#RePaintMatches()
autocmd! TextChangedI * nested call sluice#renderer#RePaintMatches()
autocmd! VimResized * nested call sluice#renderer#RePaintMatches()
" TODO this slows shit down A LOT:
autocmd! CursorMoved * nested call sluice#renderer#RePaintMatches()

" When re-entering a buffer, tell the paint methods to repain the entire
" gutter.
autocmd! BufEnter * let b:sluice_signs = {}

if !exists('b:sluice_signs') | let b:sluice_signs = {} | endif

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

" Turn on/off specific plugins
command! -nargs=1 -complete=customlist,sluice#pluginmanager#getnames -bar SluiceTogglePlugin call sluice#pluginmanager#toggle("<args>")
command! -nargs=1 -complete=customlist,sluice#pluginmanager#getnames -bar SluiceEnablePlugin call sluice#pluginmanager#setenabled("<args>",1)
command! -nargs=1 -complete=customlist,sluice#pluginmanager#getnames -bar SluiceDisablePlugin call sluice#pluginmanager#setenabled("<args>",0)

" Defaults
SluiceDisablePlugin git
SluiceDisablePlugin undercursor

"}}}
" Private Variables "{{{

" TODO what is this for, I don't remember?
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
	else
		echohl ErrorMsg
		echoe "Imagemagick 'convert' command not found or in error. Graphic icons disabled."
		echohl None
	endif
endif

"}}}
" vim: set fdm=marker noet:
