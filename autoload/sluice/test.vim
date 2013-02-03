" plugins#git tests {{{

function! TestParseDiff()
  let diff = sluice#plugins#git#ParsePatchFile('autoload/sluice/test/gitdiff.diff')
  call VUAssertEquals(sort(keys(diff)), sort(
        \['1',
        \'57','58','59','60','61','62','63','64','65','66','67','68','69',
        \'70','71','72','73','74','75','76','77','78',
        \'85','89',
        \'128']))
  call VUAssertTrue(diff['1']['removed'])
  call VUAssertTrue(diff['57']['added'])
  " 89 has both a removed line and an added line.
  call VUAssertTrue(diff['89']['removed'])
  call VUAssertTrue(diff['89']['added'])
endfunction

function! TestGitFunctions()
  call VUAssertEquals(sluice#plugins#git#getgitbranch('README'),'master')
endfunction

" }}}
" plugins#search tests"{{{

function! TestSearch()
  " Given a file full of the same deal, perform searches from various points
  " in the file. It should return the same results every time (well, taking
  " into consideration the 'max' searches.
  let @/='nothing'
  let options = { 'max_searches': 10, 'needle': 'line'}

  try
    " create a file with 60 total lines. The liens are of the pattern:
    " line
    " line line
    " line
    " line line
    " ...
    " ...
    sp abid
    normal iline line
    normal Oline
    normal 2yy29P
    $
    let bottomresults = sluice#plugins#search#data(options)
    1 
    let topresults = sluice#plugins#search#data(options)
    30 
    let middleresults = sluice#plugins#search#data(options)
  finally
    " ensure that if there are any function errors, we still close the temp
    " buffer
    bd!
  endtry

  " seven total lines, b/c some lines have two matches
  call VUAssertEquals(len(bottomresults['lines']),8)
  " but the total count should be at least 10
  call VUAssertTrue(_#sum(
        \_#map(bottomresults['lines'],
        \'let result = val["count"]'
        \)) >= 10)
  call VUAssertEquals(@/,'nothing')
  " the search didn't finish searching up:
  call VUAssertTrue(bottomresults['upmax'])
  " but it did finish searching down:
  call VUAssertFalse(bottomresults['downmax'])
  for i in range(8)
    call VUAssertTrue(has_key(bottomresults['lines'],60-i),"Not found line:". (60-i))
  endfor

  " seven total lines, b/c some lines have two matches
  call VUAssertEquals(len(topresults['lines']),7)
  " but the total count should be at least 10
  call VUAssertTrue(_#sum(
        \_#map(topresults['lines'],
        \'let result = val["count"]'
        \)) >= 10)
  " the search didn't finish searching up:
  call VUAssertFalse(topresults['upmax'])
  " but it did finish searching down:
  call VUAssertTrue(topresults['downmax'])
  for i in range(7)
    call VUAssertTrue(has_key(topresults['lines'],i+1),"Not found line:". (i+1))
  endfor

  " matches both up and down
  call VUAssertEquals(len(middleresults['lines']),14)
  " but the total count should be at least 10
  call VUAssertTrue(_#sum(
        \_#map(middleresults['lines'],
        \'let result = val["count"]'
        \)) >= 10)
  " the search didn't finish searching up:
  call VUAssertTrue(middleresults['upmax'])
  " but it did finish searching down:
  call VUAssertTrue(middleresults['downmax'])
  call VULog("middle results = ". string(middleresults))
  for i in range(14)
    call VUAssertTrue(has_key(middleresults['lines'],30+i-7),"Not found line:". (30+i-7))
  endfor
endfunction

""}}}
" plugins#undercursor tests {{{

function! TestGetBG()
  highlight! Normal guibg=#000000
  call VUAssertEquals(sluice#plugins#undercursor#getbg(),'000000')

  " doesn't pay attention to cterm...so the bg becomes 'white'
  highlight clear Normal
  highlight! Normal ctermbg=17
  call VUAssertEquals(sluice#plugins#undercursor#getbg(),'ffffff')
endfunction
" }}}
" plugins#util tests {{{

function! TestTypicalPaint()
  let options = {
        \'color': '123456',
        \'chars': 'X '
        \}
  let results = sluice#renderers#util#TypicalPaint({
        \'lines': { '1': {}, '2': {} }
        \},
        \options)
  call VULog("results = ". string(results))
  call VUAssertEquals(results['lines']['1']['fg'],'123456')
  call VUAssertEquals(results['lines']['2']['text'],'X ')
endfunction

" }}}
" renderers#slash tests"{{{

function! TestGroupNumbers()
  call VUAssertEquals(sluice#renderers#util#groupNumbers([]),[])
  call VUAssertEquals(sluice#renderers#util#groupNumbers([1]),[[1,1]])
  call VUAssertEquals(sluice#renderers#util#groupNumbers([1,2,3,4]),[[1,4]])
  call VUAssertEquals(sluice#renderers#util#groupNumbers([1,2,3,4,6]),[[1,4],[6,6]])
  call VUAssertEquals(sluice#renderers#util#groupNumbers([1,3,4,5,7]),[[1,1],[3,5],[7,7]])
endfunction

""}}}
" util#color tests {{{

function! TestHSVToRGB()
  call VUAssertEquals(sluice#util#color#HSVToRGB([0,0,0]),[0,0,0])
  call VUAssertEquals(sluice#util#color#HSVToRGB([0,0,100]),[255,255,255])
  " make sure that an over-run computes something reasonable
  call VUAssertEquals(sluice#util#color#HSVToRGB([0,0,118]),[255,255,255])
endfunction

function! TestLighterAndDarker()
  call VUAssertEquals(sluice#util#color#darker('ffffff'),'e5e5e5')
  call VUAssertEquals(sluice#util#color#darker('000000'),'000000')

  call VUAssertEquals(sluice#util#color#lighter('ffffff'),'ffffff')
  call VUAssertEquals(sluice#util#color#lighter('000000'),'191919')

  call VUAssertEquals(sluice#util#color#lighter('fdf6e3'),'ffffff')
  call VUAssertEquals(sluice#util#color#darker('fdf6e3'),'e2e2e2')
endfunction

function! TestHexToRGBAndBack()
	call VUAssertEquals(sluice#util#color#HexToRGB("000000"),[0,0,0])
	call VUAssertEquals(sluice#util#color#HexToRGB("ffffff"),[255,255,255])
	call VUAssertEquals(sluice#util#color#HexToRGB("AAAAAA"),[170,170,170])
	call VUAssertEquals(sluice#util#color#HexToRGB("fdf6e3"),[253,246,227])
	call VUAssertEquals(sluice#util#color#RGBToHex([0,0,0]),"000000")
	call VUAssertEquals(sluice#util#color#RGBToHex([255,255,255]),"ffffff")
	call VUAssertEquals(sluice#util#color#RGBToHex([32,15,180]),"200fb4")
	call VUAssertEquals(sluice#util#color#RGBToHex([253,246,227]),"fdf6e3")
endfunction

function! TestRGBToHSVAndBack()
	call VUAssertEquals(sluice#util#color#RGBToHSV([0,0,0]),[0,0,0])
	call VUAssertEquals(sluice#util#color#RGBToHSV([255,255,255]),[0,0,100])
	call VUAssertEquals(sluice#util#color#RGBToHSV([255,0,0]),[0,100,100])
	call VUAssertEquals(sluice#util#color#RGBToHSV([0,255,0]),[120,100,100])
	call VUAssertEquals(sluice#util#color#RGBToHSV([0,0,255]),[240,100,100])
	call VUAssertEquals(sluice#util#color#RGBToHSV([50,50,50]),[0,0,19])
	call VUAssertEquals(sluice#util#color#RGBToHSV([100,100,100]),[0,0,39])
	" call VUAssertEquals(RGBToHSV([187,219,255]),[212,27,100])

	call VUAssertEquals(sluice#util#color#HSVToRGB([0,0,0]),[0,0,0])
	call VUAssertEquals(sluice#util#color#HSVToRGB([100,100,100]),[84,255,0])
	call VUAssertEquals(sluice#util#color#HSVToRGB([0,100,100]),[255,0,0])
	call VUAssertEquals(sluice#util#color#HSVToRGB([120,100,100]),[0,255,0])
	call VUAssertEquals(sluice#util#color#HSVToRGB([240,100,100]),[0,0,255])

  " TODO converting between the RGB and back again really wasn't lossless,
  " try to figure out why?
	call VUAssertEquals(sluice#util#color#RGBToHSV([253,246,227]),[127,0,99])
	call VUAssertEquals(sluice#util#color#HSVToRGB([127,0,99]),[252,252,252])
endfunction
" }}}
" util#location "{{{
function! TestLoadRegisters()
	let from = "something"
	let @8 = from
	let registers = sluice#util#location#SaveRegisters()
	call VUAssertEquals(from,registers["reg-8"])
	let registers["reg-8"] = from ."2"
	call sluice#util#location#LoadRegisters(registers)
	call VUAssertEquals(from ."2",@8)
endfunction

function! TestConvertToModuloOffset()
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(1,1,2,2),0)
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(2,1,2,2),0)

  " if you are on the first line it should be 0
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(1,1,31,31),0)
  " if you are on the last line of the file, it'll be something >= 0
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(31,1,31,31),0)
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(1,70,100,100),0)
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(100,70,100,100),69)
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(50,70,100,100),19)

  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(1,1,45,170),0)
endf

function! TestConvertToPercentOffset()
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(1,1,2,2),1)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(2,1,2,2),2)

  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(50,70,100,100),85)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(10,6,10,10),10)
endfunction

function! TestPercentAndModule()
  " test several lines one after another. The value should be logical..
  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(1,1,45,170),0)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(1,1,45,170),1)

  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(2,1,45,170),26)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(2,1,45,170),1)

  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(3,1,45,170),52)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(3,1,45,170),1)

  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(4,1,45,170),79)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(4,1,45,170),1)

  call VUAssertEquals(sluice#util#location#ConvertToModuloOffset(5,1,45,170),5)
  call VUAssertEquals(sluice#util#location#ConvertToPercentOffset(5,1,45,170),2)
endfunction

function! TestGetHumanReadables()
	call VUAssertEquals(sluice#util#location#GetHumanReadables(""),"")
	call VUAssertEquals(sluice#util#location#GetHumanReadables("aa"),"aa")
	call VUAssertEquals(sluice#util#location#GetHumanReadables(".."),"dtdt")
	call VUAssertEquals(sluice#util#location#GetHumanReadables("\\\\"),"bsbs")
	call VUAssertEquals(sluice#util#location#GetHumanReadables("//"),"fsfs")
	call VUAssertEquals(sluice#util#location#GetHumanReadables("--"),"dada")
endfunction
"}}}
" util#icon"{{{

function! TestMakeImage()
  let image = sluice#renderers#icon#makeImage()
  " base case:
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px"></svg>')
  " one line on the top row:
  call image.addRectangle('000000',0,0,50,2)
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="0" y="0" height="2" width="50" style="fill: #000000;" />'.
        \'</svg>')
endfunction

function! TestGeneratePNGFile()
  let image = sluice#renderers#icon#makeImage()
  call image.addRectangle('000000',0,0,50,2)
  call image.generatePNGFile('test')
endfunction

function! TestAddRectangleWithAlign()
  " Base case
  let aligns = [ 'left', 'right', 'center' ]
  for a in aligns
    let image = sluice#renderers#icon#makeImage()
    call image.placeRectangle('000000',10,100,2,a)
    call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
          \'<rect x="0" y="10" height="2" width="50" style="fill: #000000;" />'.
          \'</svg>')
  endfor
  let image = sluice#renderers#icon#makeImage()
  call image.placeRectangle('000000',10,50,2,'right')
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="25" y="10" height="2" width="25" style="fill: #000000;" />'.
        \'</svg>')
  let image = sluice#renderers#icon#makeImage()
  call image.placeRectangle('000000',10,50,2,'center')
  call VUAssertEquals(image.generateSVG(),'<svg width="50px" height="50px">'.
        \'<rect x="12" y="10" height="2" width="25" style="fill: #000000;" />'.
        \'</svg>')
endfunction

function! TestGeneratePNGOffset()
  " make the image, add a couple things by line...
  " I was thinking that adding the line number into the ultimate image file
  " would be handy (so you say how many lines there are and it computes the
  " size? width = 10, height = # lines * 10
  "
  " then translate
  let lines = 10
  let image = sluice#renderers#icon#makeImage(10,10*lines)
  for i in range(lines)
    if i % 2 == 0
      call image.addRectangle('000000',0,i*10,50,10)
      call image.addText(string(i%2),'red',9,i*10+9)
      call image.placeRectangle('000000',i*10,50,2,'left')
    else
      call image.addRectangle('ff0000',0,i*10,50,10)
      call image.addText(string(i%2),'black',9,i*10+9)
      call image.placeRectangle('0000ff',i*10,50,2,'right')
    endif
  endfor
  call image.generatePNGFile('nooffset',0,10,10,10)
  " ensure that a hash is a big string.
  let filehash = image.generateHash()
  call VUAssertTrue(len(filehash) > 0)

  call VULog("one")
  let onehash = image.generateHash(0,10,10,10)
  call VUAssertNotSame(filehash,onehash)

  call VULog("two")
  let twohash = image.generateHash(0,20,10,10)
  call VUAssertNotSame(twohash,onehash)
  call VUAssertNotSame(twohash,filehash)

  call VULog("three")
  let threehash = image.generateHash(0,30,10,10)
  call VUAssertEquals(threehash,onehash)
  call VUAssertNotSame(threehash,filehash)

  let fourhash = image.generateHash(0,40,10,10)
  call VUAssertEquals(fourhash,twohash)
  call VUAssertNotSame(fourhash,filehash)

  call VULog("onehalf")
  let onehalfhash = image.generateHash(0,5,10,10)
  call VULog("threehalf")
  let threehalfhash = image.generateHash(0,25,10,10)
  call VUAssertEquals(onehalfhash,threehalfhash)
endfunction

function! TestGenerateHash()
  let image = sluice#renderers#icon#makeImage(10,50)
  call image.addRectangle('000000',0,0,10,40)
  " a small widget painted from 7-10 so it should appear in
  " blocks 0-9 and 10-19
  call image.addRectangle('123444',0,7,10,4)

  call VUAssertNotSame(image.generateHash(0,0,10,10),image.generateHash(0,10,10,10))

  " compare the 10-19 block witht the 20-29 should not be the same since a
  " sliver of the 123444 is in there.
  call VUAssertNotSame(image.generateHash(0,10,10,10),image.generateHash(0,20,10,10))


  let image = sluice#renderers#icon#makeImage(10,100)
  call image.addRectangle('000000',0,0,10,100)
  call image.addRectangle('c6c6c6',0,9,10,2)

  call VUAssertNotSame(image.generateHash(0,0,0,0),image.generateHash(0,50,10,10))
  call VUAssertNotSame(image.generateHash(0,10,0,0),image.generateHash(0,50,10,10))
endfunction

""}}}
" renderer tests"{{{
"function! TestCombineData()
"  " put your curser in this block somewhere and then type ":call VUAutoRun()"
"  " TODO these are still NOT passing.
"  let w:save_cursor = winsaveview()
"  call VUAssertEquals(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test1plugin', 'options': { 'render': 'sluice#test#test1paint' }}
"        \ ],10,1,10)['lines'],
"        \
"        \ {})
"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test2plugin', 'options': { 'render': 'sluice#test#test2paint'}}
"        \ ],10,1,10)['lines'],
"        \
"        \ {'1':{'sluice#test#test2plugin': {
"        \   'count': 1,
"        \   'bg': 'testbg',
"        \   'fg': 'testhi',
"        \   'text': '..',
"        \   'line': 1,
"        \   'signLine': 1,
"        \   'modulo': 0
"        \ } }}
"        \)
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test1plugin', 'options': { 'render': 'sluice#test#test1paint'}},
"        \ {'plugin':'sluice#test#test2plugin','options': { 'render': 'sluice#test#test2paint'}}
"        \ ],10,1,10)['lines'],
"        \ 
"        \ {'1': {'sluice#test#test2plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ } }})
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test2plugin', 'options': { 'render': 'sluice#test#test1paint'}},
"        \ {'plugin':'sluice#test#test2plugin','options': { 'render': 'sluice#test#test2paint'}}
"        \ ],10,1,10)['lines'],
"        \
"        \ {'1': {'sluice#test#test2plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ } }})
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

"  " Two plugins that have data, but only one of them renders anything.
"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test3plugin', 'options': { 'render': 'sluice#test#test1paint'}},
"        \ {'plugin':'sluice#test#test2plugin','options': { 'render': 'sluice#test#test2paint' }}
"        \ ],10,1,10)['lines'],
"        \
"        \ {'1': {'sluice#test#test2plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ } }})
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

"  " if one data source has an extra key it should always be in the results
"  " regardless of order:
"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test4plugin','options': { 'render': 'sluice#test#test2paint'}},
"        \ {'plugin':'sluice#test#test3plugin','options': { 'render': 'sluice#test#test2paint' }}
"        \ ],10,1,10)['lines'],
"        \
"        \ {'1': {'sluice#test#test3plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ }, 'sluice#test#test4plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'isvis':1,
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ } }})
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

"  " non intersecting data sets, both should be there.
"  let diff = vimunit#util#diff(sluice#renderer#CombineData([
"        \ {'plugin':'sluice#test#test4plugin','options': { 'render': 'sluice#test#test3paint'}},
"        \ {'plugin':'sluice#test#test5plugin','options': { 'render': 'sluice#test#test3paint'}}
"        \ ],10,1,10)['lines'],
"        \
"        \ { '1': {'sluice#test#test4plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'isvis':1,
"        \  'line': 1,
"        \  'signLine': 1,
"        \  'modulo': 0
"        \ }},
"        \ '2': {'sluice#test#test4plugin': {
"        \  'count':2,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 2,
"        \  'signLine': 2,
"        \  'modulo': 0
"        \ }},
"        \ '5': {'sluice#test#test5plugin': {
"        \  'count':1,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 5,
"        \  'signLine': 5,
"        \  'modulo': 0
"        \ }},
"        \ '6': {'sluice#test#test5plugin': {
"        \  'count':2,
"        \  'text':'..',
"        \  'fg':'testhi',
"        \  'bg':'testbg',
"        \  'line': 6,
"        \  'signLine': 6,
"        \  'modulo': 0
"        \ } }})
"  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
"endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line,dict)
endfunction

function! TestDoPaintMatches()
	call VUAssertEquals(sluice#renderer#DoPaintMatches(5,1,5,{'lines':{}},"UnpaintTestStub","PaintTestStub"),{})
	" if all lines are currently visible, don't do anything:
	" first just paint one line. We expect that the line '1' would be painted,
	" and that the highlight group is created (and 'sluice#test#test1plugin' is called).
	unlet! b:cached_signs
  let result = sluice#renderer#DoPaintMatches(6,1,5,
        \{'lines':{1:{'sluice#test#test1plugin': {
        \  'line':1,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'left','iconcolor':'000000'}
        \ }}, 'gutterImage': sluice#renderers#icon#makeImage()},
        \"UnpaintTestStub","PaintTestStub")
  let diff = vimunit#util#diff(result['1']['plugins'],[ 
        \    { 'plugin': 'sluice#test#test1plugin', 'line': 1, 'text':'XX',
        \      'fg':'000000','bg':'000000','iconwidth':50,
        \      'iconalign':'left','iconcolor':'000000'}
        \  ])
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))
  call VUAssertEquals(keys(result),['1'])

	" two lines, implies some reconciliation should be happening here:
	let g:mv_plugins = []
	call sluice#renderer#add('sluice#test#test1plugin',{ 'render': 'sluice#test#nopaint' })
	call sluice#renderer#add('sluice#test#test2plugin',{ 'render': 'sluice#test#rrpaint' })
  let result = sluice#renderer#DoPaintMatches(10,1,5,
        \{'lines':{1:{ 'sluice#test#test1plugin': 
        \  { 'line':1,'text':'//','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000'},
        \  'sluice#test#test2plugin':
        \  { 'line':1,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000'}
        \},
        \2:{'sluice#test#test1plugin':
        \  { 'line':2,'text':'XX','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'left','iconcolor':'000000'}
        \}}, 'gutterImage': sluice#renderers#icon#makeImage() },
        \"UnpaintTestStub","PaintTestStub")

  let diff = vimunit#util#diff(result['1']['plugins'],[ 
        \    {'plugin': 'sluice#test#test2plugin','line': 1, 'text': 'RR', 'fg': '000000', 'bg': '000000', 'iconwidth': 50, 'iconalign':'right', 'iconcolor': '000000'},
        \    {'plugin': 'sluice#test#test1plugin', 'line':1,'text':'//','fg':'000000','bg':'000000','iconwidth':50,'iconalign':'right','iconcolor':'000000'},
        \    {'plugin': 'sluice#test#test1plugin','line': 2, 'text': 'XX', 'fg': '000000', 'bg': '000000', 'iconwidth': 50, 'iconalign':'left', 'iconcolor': '000000'}
        \  ])
  call VUAssertEquals(len(diff),0,vimunit#util#diff2str(diff))

  let result = sluice#renderer#DoPaintMatches(10,6,10,
        \{'lines':{1:{'sluice#test#test1plugin': { 'line':1,'text':'XX','fg':'000000','bg':'000000'}},
        \10:{'sluice#test#test1plugin': { 'line':10,'text':'XX','fg':'000000','bg':'000000'}} },
        \  'gutterImage': sluice#renderers#icon#makeImage()},
        \"UnpaintTestStub","PaintTestStub")
  call VUAssertEquals(sort(keys(result)),sort(['6','10']))

  " When a plugin is removed, it should not longer be in the list of plugins
	call sluice#renderer#remove('sluice#test#test2plugin')
  call VUAssertEquals(g:mv_plugins,[{ 'plugin': 'sluice#test#test1plugin', 'options': { 'render': 'sluice#test#nopaint' }}])
endfunction

"}}}
" renderer admin function tests {{{
function! TestEnableDisable()
  " base case - no globals == disabled.
  unlet g:sluice_enabled
  unlet g:sluice_default_enabled
  call VUAssertFalse(sluice#renderer#getenabled())

  " global Sluice setting disabled both functions should be useless.
  let g:sluice_enabled = 0
  let g:sluice_default_enabled = 0

  call VUAssertFalse(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(1)
  call VUAssertFalse(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(0)

  " new files aren't enabled either
  split 0file.txt
  call VUAssertFalse(sluice#renderer#getenabled())
  bd

  " When enabled (but not sluice_default_enabled) the enable/disable should
  " enable and disable: 
  let g:sluice_enabled = 1
  call VUAssertFalse(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(1)
  call VUAssertTrue(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(0)
  call VUAssertFalse(sluice#renderer#getenabled())

  " TODO make a split and verify that when going into a new window, that Sluice
  " isn't enabled by default.
  split 1file.txt
  call VUAssertFalse(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(1)
  call VUAssertTrue(sluice#renderer#getenabled())
  bd

  " When sluice_default_enabled is setup, then opening a new file would have
  " Sluice turned on.
  let g:sluice_default_enabled = 1
  split 2file.txt
  call VUAssertTrue(sluice#renderer#getenabled())
  call sluice#renderer#setenabled(0)
  call VUAssertFalse(sluice#renderer#getenabled())
  quit
endfunction

function! TestToggleMacroMode()
  " base case - no globals == disabled.
  let g:sluice_enabled = 1
  let g:sluice_default_enabled = 1
  let g:sluice_default_macromode = 1
  if exists('b:sluice_enabled') | unlet b:sluice_enabled | endif
  if exists('b:sluice_macromode') | unlet b:sluice_macromode | endif
 
  call VUAssertTrue(sluice#renderer#getenabled())
  call VUAssertEquals(b:sluice_macromode,1)

  call sluice#renderer#setmacromode(0)
  call VUAssertEquals(sluice#renderer#getmacromode(),0)
  call sluice#renderer#setmacromode(1)
  call VUAssertEquals(sluice#renderer#getmacromode(),1)

  split 0file.txt
  call VUAssertTrue(sluice#renderer#getenabled())
  call VUAssertEquals(sluice#renderer#getmacromode(),1)
  bd

  let g:sluice_default_macromode = 0
  split 1file.txt
  call VUAssertTrue(sluice#renderer#getenabled())
  call VUAssertEquals(sluice#renderer#getmacromode(),0)
  bd
endfunction

"}}}

" vim: set fdm=marker :
