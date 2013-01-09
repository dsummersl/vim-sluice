" util#color tests {{{

function! TestUniq()
	call VUAssertEquals(mvom#util#color#Uniq([]),[])
	call VUAssertEquals(mvom#util#color#Uniq([1,2,3]),[1,2,3])
	call VUAssertEquals(mvom#util#color#Uniq([3,2,1]),[3,2,1])
	call VUAssertEquals(mvom#util#color#Uniq([3,2,1,2,3]),[3,2,1])
	call VUAssertEquals(mvom#util#color#Uniq(['onea','oneb','onea']),['onea','oneb'])
endfunction

function! TestHexToRGBAndBack()
	call VUAssertEquals(mvom#util#color#HexToRGB("000000"),[0,0,0])
	call VUAssertEquals(mvom#util#color#HexToRGB("ffffff"),[255,255,255])
	call VUAssertEquals(mvom#util#color#HexToRGB("AAAAAA"),[170,170,170])
	call VUAssertEquals(mvom#util#color#RGBToHex([0,0,0]),"000000")
	call VUAssertEquals(mvom#util#color#RGBToHex([255,255,255]),"ffffff")
	call VUAssertEquals(mvom#util#color#RGBToHex([32,15,180]),"200fb4")
endfunction

function! TestRGBToHSVAndBack()
	call VUAssertEquals(mvom#util#color#RGBToHSV([0,0,0]),[0,0,0])
	call VUAssertEquals(mvom#util#color#RGBToHSV([255,255,255]),[0,0,100])
	call VUAssertEquals(mvom#util#color#RGBToHSV([255,0,0]),[0,100,100])
	call VUAssertEquals(mvom#util#color#RGBToHSV([0,255,0]),[120,100,100])
	call VUAssertEquals(mvom#util#color#RGBToHSV([0,0,255]),[240,100,100])
	call VUAssertEquals(mvom#util#color#RGBToHSV([50,50,50]),[0,0,19])
	call VUAssertEquals(mvom#util#color#RGBToHSV([100,100,100]),[0,0,39])
	" call VUAssertEquals(RGBToHSV([187,219,255]),[212,27,100])

	call VUAssertEquals(mvom#util#color#HSVToRGB([0,0,0]),[0,0,0])
	call VUAssertEquals(mvom#util#color#HSVToRGB([100,100,100]),[84,255,0])
	call VUAssertEquals(mvom#util#color#HSVToRGB([0,100,100]),[255,0,0])
	call VUAssertEquals(mvom#util#color#HSVToRGB([120,100,100]),[0,255,0])
	call VUAssertEquals(mvom#util#color#HSVToRGB([240,100,100]),[0,0,255])
endfunction

function! TestGetSignName()
	call VUAssertEquals(mvom#util#color#GetSignName({'fg':'000000','bg':'111111','text':'--',
        \'plugins':[ { 'plugin':'a', 'modulo': 3, 'iconcolor': 'bbbbbb', 'iconwidth': 50, 'iconalign': 'left'} ]
        \}),"a021ace522e51ce")
	call VUAssertEquals(mvom#util#color#GetSignName({'fg':'000000','bg':'111111','text':'--',
        \'plugins':[ {'plugin': 'a', 'modulo': 3, 'iconcolor': 'bbbbbb', 'iconwidth': 50, 'iconalign': 'left'},
        \  { 'plugin': 'b', 'modulo': 5, 'iconcolor': 'cccccc', 'iconwidth': 50, 'iconalign': 'center'}
        \]}),"3cdc21e65eec1bb")
endfunction
" }}}
" util#location "{{{
function! TestLoadRegisters()
	let from = "something"
	let @8 = from
	let registers = mvom#util#location#SaveRegisters()
	call VUAssertEquals(from,registers["reg-8"])
	let registers["reg-8"] = from ."2"
	call mvom#util#location#LoadRegisters(registers)
	call VUAssertEquals(from ."2",@8)
endfunction

function! TestConvertToModuloOffset()
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(1,1,2,2),0)
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(2,1,2,2),0)

  " if you are on the first line it should be 0
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(1,1,31,31),0)
  " if you are on the last line of the file, it'll be something >= 0
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(31,1,31,31),0)
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(1,70,100,100),0)
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(100,70,100,100),69)
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(50,70,100,100),19)

  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(1,1,45,170),0)
endf

function! TestConvertToPercentOffset()
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,1,2,2),1)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(2,1,2,2),2)

  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(50,70,100,100),85)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(10,6,10,10),10)
endfunction

function! TestPercentAndModule()
  " test several lines one after another. The value should be logical..
  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(1,1,45,170),0)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,1,45,170),1)

  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(2,1,45,170),26)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(2,1,45,170),1)

  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(3,1,45,170),52)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(3,1,45,170),1)

  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(4,1,45,170),79)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(4,1,45,170),1)

  call VUAssertEquals(mvom#util#location#ConvertToModuloOffset(5,1,45,170),5)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(5,1,45,170),2)
endfunction

function! TestGetHumanReadables()
	call VUAssertEquals(mvom#util#location#GetHumanReadables(""),"")
	call VUAssertEquals(mvom#util#location#GetHumanReadables("aa"),"aa")
	call VUAssertEquals(mvom#util#location#GetHumanReadables(".."),"dtdt")
	call VUAssertEquals(mvom#util#location#GetHumanReadables("\\\\"),"bsbs")
	call VUAssertEquals(mvom#util#location#GetHumanReadables("//"),"fsfs")
	call VUAssertEquals(mvom#util#location#GetHumanReadables("--"),"dada")
endfunction
"}}}
" util#icon"{{{

function! TestMakeImage()
  let image = mvom#renderers#icon#makeImage()
  " base case:
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px"></svg>')
  " one line on the top row:
  call image.addRectangle('000000',0,0,50,2)
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="0" y="0" height="2" width="50" style="fill: #000000;"/>'.
        \'</svg>')
endfunction

function! TestGeneratePNGFile()
  let image = mvom#renderers#icon#makeImage()
  call image.addRectangle('000000',0,0,50,2)
  call image.generatePNGFile('test')
endfunction

function! TestAddRectangleWithAlign()
  " Base case
  let aligns = [ 'left', 'right', 'center' ]
  for a in aligns
    let image = mvom#renderers#icon#makeImage()
    call image.placeRectangle('000000',10,100,2,a)
    call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
          \'<rect x="0" y="10" height="2" width="50" style="fill: #000000;"/>'.
          \'</svg>')
  endfor
  let image = mvom#renderers#icon#makeImage()
  call image.placeRectangle('000000',10,50,2,'right')
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="25" y="10" height="2" width="25" style="fill: #000000;"/>'.
        \'</svg>')
  let image = mvom#renderers#icon#makeImage()
  call image.placeRectangle('000000',10,50,2,'center')
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="12" y="10" height="2" width="25" style="fill: #000000;"/>'.
        \'</svg>')
endfunction

""}}}
" renderer tests"{{{
function! TestCombineData()
  " put your curser in this block somewhere and then type ":call VUAutoRun()"
	" TODO these are still NOT passing.
	let w:save_cursor = winsaveview()
	call VUAssertEquals(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test1plugin', 'options': { 'render': 'mvom#test#test1paint' }}
        \ ]),
        \
        \ {})
  let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test2plugin', 'options': { 'render': 'mvom#test#test2paint'}}
        \ ]),
        \
        \ {'1':{'mvom#test#test2plugin': {
        \   'count': 1,
        \   'bg': 'testbg',
        \   'fg': 'testhi',
        \   'text': '..'
        \ } }}
        \)
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

	let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test1plugin', 'options': { 'render': 'mvom#test#test1paint'}},
        \ {'plugin':'mvom#test#test2plugin','options': { 'render': 'mvom#test#test2paint'}}
        \ ]),
        \ 
        \ {'1': {'mvom#test#test2plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ } }})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

	let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test2plugin', 'options': { 'render': 'mvom#test#test1paint'}},
        \ {'plugin':'mvom#test#test2plugin','options': { 'render': 'mvom#test#test2paint'}}
        \ ]),
        \
        \ {'1': {'mvom#test#test2plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ } }})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

	" Two plugins that have data, but only one of them renders anything.
	let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test3plugin', 'options': { 'render': 'mvom#test#test1paint'}},
        \ {'plugin':'mvom#test#test2plugin','options': { 'render': 'mvom#test#test2paint' }}
        \ ]),
        \
        \ {'1': {'mvom#test#test2plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ } }})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

	" if one data source has an extra key it should always be in the results
	" regardless of order:
	let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test4plugin','options': { 'render': 'mvom#test#test2paint'}},
        \ {'plugin':'mvom#test#test3plugin','options': { 'render': 'mvom#test#test2paint' }}
        \ ]),
        \
        \ {'1': {'mvom#test#test3plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ }, 'mvom#test#test4plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg',
        \  'isvis':1
        \ } }})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

	" non intersecting data sets, both should be there.
	let diff = vimunit#util#diff(mvom#renderer#CombineData([
        \ {'plugin':'mvom#test#test4plugin','options': { 'render': 'mvom#test#test3paint'}},
        \ {'plugin':'mvom#test#test5plugin','options': { 'render': 'mvom#test#test3paint'}}
        \ ]),
        \
        \ { '1': {'mvom#test#test4plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg',
        \  'isvis':1
        \ }},
        \ '2': {'mvom#test#test4plugin': {
        \  'count':2,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ }},
        \ '5': {'mvom#test#test5plugin': {
        \  'count':1,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ }},
        \ '6': {'mvom#test#test5plugin': {
        \  'count':2,
        \  'text':'..',
        \  'fg':'testhi',
        \  'bg':'testbg'
        \ } }})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line,dict)
endfunction

function! TestDoPaintMatches()
  " TODO make mocks of paint and unpaint. verify that unpaint and paint were never
  " called.
  let g:mvom_alpha = 1

	call VUAssertEquals(mvom#renderer#DoPaintMatches(5,1,5,{},"UnpaintTestStub","PaintTestStub"),{})
	" if all lines are currently visible, don't do anything:
	" first just paint one line. We expect that the line '1' would be painted,
	" and that the highlight group is created (and 'mvom#test#test1plugin' is called).
	unlet! b:cached_signs
  let diff = vimunit#util#diff(mvom#renderer#DoPaintMatches(6,1,5,
        \{1:{'mvom#test#test1plugin': {
        \  'line':1,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'left','iconcolor':'000000'}
        \ }},
        \"UnpaintTestStub","PaintTestStub")
        \,
        \{1:{
        \  'plugins':[ 
        \    { 'plugin': 'mvom#test#test1plugin', 'line': 1, 'modulo': 0, 'text':'XX',
        \      'fg':'000000','bg':'000000','iconwidth':50,'iconalign':'left','iconcolor':'000000'}
        \  ],
        \  'line': 1, 'icon': g:mvom_icon_cache .'d0bf1e398e5763d.png',
        \  'text':'XX','fg':'000000','bg':'000000','visible':1,
        \  'iconwidth':50,'iconalign':'left','iconcolor':'000000'}})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
	call VUAssertEquals(exists("g:mvom_sign_d0bf1e398e5763d"),1)
	" two lines, implies some reconciliation should be happening here:
	unlet! g:mvom_sign_d0bf1e398e5763d
	let g:mv_plugins = []
	call mvom#renderer#add('mvom#test#test1plugin',{ 'render': 'mvom#test#nopaint' })
	call mvom#renderer#add('mvom#test#test2plugin',{ 'render': 'mvom#test#rrpaint' })
  let diff = vimunit#util#diff(mvom#renderer#DoPaintMatches(10,1,5,
        \{1:{ 'mvom#test#test1plugin': 
        \  { 'line':1,'text':'//','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000'},
        \  'mvom#test#test2plugin':
        \  { 'line':1,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000'}
        \},
        \2:{'mvom#test#test1plugin':
        \  { 'line':2,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'left','iconcolor':'000000'}
        \}},
        \"UnpaintTestStub","PaintTestStub"),
        \
        \{1:{
        \  'plugins': [
        \    {'plugin': 'mvom#test#test1plugin','line': 1, 'modulo': 0, 'text': '//', 'fg': '000000', 'bg': '000000', 'iconwidth': 50, 'iconalign':'right', 'iconcolor': '000000'},
        \    {'plugin': 'mvom#test#test2plugin', 'line':1,'text':'RR','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000', 'modulo': 0},
        \    {'plugin': 'mvom#test#test1plugin','line': 2, 'modulo': 5, 'text': 'XX', 'fg': '000000', 'bg': '000000', 'iconwidth': 50, 'iconalign':'left', 'iconcolor': '000000'}
        \  ],
        \  'plugin': 'mvom#test#test1plugin','line': 2, 'iconwidth': 50, 'iconalign': 'left', 'iconcolor': '000000', 'modulo': 5,
        \  'text':'XX','fg':'000000','bg':'000000','visible':1, 'icon': g:mvom_icon_cache .'caa11b4fcd55986.png'
        \ }
        \})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
	call VUAssertEquals(exists("g:mvom_sign_caa11b4fcd55986"),1)
	unlet! g:mvom_sign_caa11b4fcd55986
  let diff = vimunit#util#diff(mvom#renderer#DoPaintMatches(10,6,10,
        \{1:{'mvom#test#test1plugin': { 'line':1,'text':'XX','fg':'000000','bg':'000000'}},
        \10:{'mvom#test#test1plugin': { 'line':10,'text':'XX','fg':'000000','bg':'000000'}} },
        \"UnpaintTestStub","PaintTestStub"),
        \
        \{6:{'plugins':
        \  [{'plugin': 'mvom#test#test1plugin', 'line': 1, 'text':'XX','fg':'000000','bg':'000000','modulo': 0}],
        \  'line': 1, 'text':'XX','fg':'000000','bg':'000000','visible':0},
        \10:{'plugins':
        \  [{ 'plugin': 'mvom#test#test1plugin', 'line':10, 'text':'XX','fg':'000000','bg':'000000','modulo': 5 }],
        \  'line':10,'text':'XX','fg':'000000','bg':'000000','visible':1,'icon': g:mvom_icon_cache .'9dd4e461268c803.png'}
        \})
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
	call VUAssertEquals(exists("g:mvom_sign_9dd4e461268c803"),1)
	" dubgging call
	" echo mvom#renderer#DoPaintMatches(line('$'),line('w0'),line('w$'),mvom#renderer#CombineData(g:mv_plugins),"UnpaintTestSign","PaintTestStub")

  " When a plugin is removed, it should not longer be in the list of plugins
	call mvom#renderer#remove('mvom#test#test2plugin')
  call VUAssertEquals(g:mv_plugins,[{ 'plugin': 'mvom#test#test1plugin', 'options': { 'render': 'mvom#test#nopaint' }}])
endfunction

"}}}
" renderer admin function tests {{{
function! TestEnableDisable()
  " base case - no globals == disabled.
  unlet g:mvom_enabled
  unlet g:mvom_default_enabled
  call VUAssertFalse(mvom#renderer#getenabled())

  " global MVOM setting disabled both functions should be useless.
  let g:mvom_enabled = 0
  let g:mvom_default_enabled = 0

  call VUAssertFalse(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(1)
  call VUAssertFalse(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(0)

  " new files aren't enabled either
  split 0file.txt
  call VUAssertFalse(mvom#renderer#getenabled())
  quit

  " When enabled (but not mvom_default_enabled) the enable/disable should
  " enable and disable: 
  let g:mvom_enabled = 1
  call VUAssertFalse(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(1)
  call VUAssertTrue(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(0)
  call VUAssertFalse(mvom#renderer#getenabled())

  " TODO make a split and verify that when going into a new window, that MVOM
  " isn't enabled by default.
  split 1file.txt
  call VUAssertFalse(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(1)
  call VUAssertTrue(mvom#renderer#getenabled())
  quit

  " When mvom_default_enabled is setup, then opening a new file would have
  " MVOM turned on.
  let g:mvom_default_enabled = 1
  split 2file.txt
  call VUAssertTrue(mvom#renderer#getenabled())
  call mvom#renderer#setenabled(0)
  call VUAssertFalse(mvom#renderer#getenabled())
  quit
endfunction
"}}}

"call VURunAllTests()

" vim: set fdm=marker :
