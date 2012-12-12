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
" Builtin data sources {{{
" The basic idea for this is that there are X plugins supported and each
" plugin is expected to have specific function names:
"
" <plugin>Init() -- called the first time its used
" <plugin>Enabled() -- called on repaints... 1 for true, 0 for false.
" <plugin>#Data(): return data. 
" Each data uses a 'num'(row number) as key and then the following:
" {
" 	'count': number of occurrances on this line
" }
" Note: you can move the cursor around as much as you want as the position has
" been saved and will be restored after this method call.

" }}}
" Builtin rendering types {{{
" The rendering types are pluggable. Here is the expected format for them:
" <render>Init() -- init anything it needs to init.
" <render>PaintMacro() -- return a dictionary telling what symbols to place
" in macro mode.
" Should have the following keys for each line:
" {
"   'text':  -- 2 symbols to display if there is a match
"   'fg': -- foreground
"   'bg': -- background
"   'linehi': -- highlight for the group. Probably not meaningful for macro mode...
" }
" <render>Paint(vals) -- return a dictionary telling what symbols to place
" in micro mode.
" vals param has the following keys:
" {
" 	'count': --- number of ... whatever... matches, links, etc
" 	'line': --- line of concern
" }
" Should have the following keys:
" {
"   'text':  -- (optional) 2 symbols to display if there is a match
"   'fg': -- foreground
"   'bg': -- background
"   'linehi': -- highlight for the group
" }
"

" }}}
" Private Variables "{{{
if !exists('w:mvom_lastcalldisabled') | let w:mvom_lastcalldisabled=1 | endif
"}}}
" Default Configuration"{{{
" This handles all the slow/fastness of responsiveness of the entire plugin:
set updatetime=100

" Maximum number of forward and backward searches to performed
if !exists('g:mvom_max_searches ') | let g:mvom_max_searches = 75 | endif

" default background color of the gutter:
if !exists('g:mvom_default_bg') | let g:mvom_default_bg = 'dddddd' | endif
exe "autocmd BufNewFile,BufRead * highlight! SignColumn guifg=white guibg=#". g:mvom_default_bg

" Slash options:
if !exists('g:mvom_slash_chars ') | let g:mvom_slash_chars ='/ ' | endif
if !exists('g:mvom_slash_color ') | let g:mvom_slash_color ='0055ff' | endif

" Ex options (when Slash/Backslash overlap):
if !exists('g:mvom_ex_chars ') | let g:mvom_ex_chars ='X ' | endif
if !exists('g:mvom_ex_color ') | let g:mvom_ex_color ='0055ff' | endif

" Backslash options:
if !exists('g:mvom_backslash_chars ') | let g:mvom_backslash_chars ='\ ' | endif
if !exists('g:mvom_backslash_color ') | let g:mvom_backslash_color ='00ff00' | endif

" UnderCursor options:
" TODO ideally I'd read the hl-IncSearch colors (but I don't know quite how...)
if !exists('g:mvom_undercursor_bg ') | let g:mvom_undercursor_bg ='e5f1ff' | endif
if !exists('g:mvom_undercursor_fg ') | let g:mvom_undercursor_fg ='000000' | endif

" Background options:
" showinline will show both the highlight both the areas that correspond to
" the current visible window, but also make the area where the cursor is
" slightly darker:
if !exists('g:mvom_bg_showinline') | let g:mvom_bg_showinline=1 | endif

" Configuration:
if !exists('g:mvom_enabled') | let g:mvom_enabled=1 | endif
if !exists('g:mvom_loaded')
	" Setup the type of plugins you want:
	" Show the last search with //
	call mvom#renderer#setup('search','slash')
	" Show all keywords in the file that match whats under your cursor with \\
	"call mvom#renderer#setup('undercursor','backslash')
	" Show the visible portion with a darker background
	call mvom#renderer#setup('window','background')
	let g:mvom_loaded = 1
endif
"}}}
" vim: set fdm=marker noet:
