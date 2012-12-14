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
	call VUAssertEquals(mvom#util#color#GetSignName({'fg':'000000','bg':'111111','text':'--'}),"MVOM_000000111111_dada")
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

function! TestConvertToPercentOffset()
  " put your curser in this block somwhere and then type ":call VUAutoRun()"
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(mvom#util#location#ConvertToPercentOffset(50,70,100,100),85)
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
" renderer tests"{{{
function! TestCombineData()
  " put your curser in this block somewhere and then type ":call VUAutoRun()"
	" TODO these are still NOT passing.
	let w:save_cursor = winsaveview()
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test1plugin','render':'mvom#test#test1paint'}]),{})
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test2plugin','render':'mvom#test#test2paint'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test2plugin'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test1plugin','render':'mvom#test#test1paint'},{'plugin':'mvom#test#test2plugin','render':'mvom#test#test2paint'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test2plugin'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test2plugin','render':'mvom#test#test1paint'},{'plugin':'mvom#test#test2plugin','render':'mvom#test#test2paint'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test2plugin'], 'line':1, 'bg':'testbg'}})
	" expect line 1 to have count=2 and then a line 2 of count 2
	" but then just the rendering for test2 will happen so...same old thing
	" there.
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test3plugin','render':'mvom#test#test1paint'},{'plugin':'mvom#test#test2plugin','render':'mvom#test#test2paint'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test3plugin','mvom#test#test2plugin'], 'line':1, 'bg':'testbg'}})
	" if one data source has an extra key it should always be in the results
	" regardless of order:
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test4plugin','render':'mvom#test#test2paint'},{'plugin':'mvom#test#test3plugin','render':'mvom#test#test2paint'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test4plugin','mvom#test#test3plugin'], 'line':1, 'bg':'testbg', 'isvis':1}})
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test3plugin','render':'mvom#test#test2paint'},{'plugin':'mvom#test#test4plugin','render':'mvom#test#test2paint'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test3plugin','mvom#test#test4plugin'], 'line':1, 'bg':'testbg', 'isvis':1}})
	" non intersecting data sets, both should be there.
	call VUAssertEquals(mvom#renderer#CombineData([{'plugin':'mvom#test#test4plugin','render':'mvom#test#test3paint'},{'plugin':'mvom#test#test5plugin','render':'mvom#test#test3paint'}]), { '1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test4plugin'], 'line':1, 'bg':'testbg', 'isvis':1}, '2':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test4plugin'], 'line':2, 'bg':'testbg'}, '5':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test5plugin'], 'line':5, 'bg':'testbg'}, '6':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['mvom#test#test5plugin'], 'line':6, 'bg':'testbg'}, })
endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line)
endfunction

function! TestDoPaintMatches()
	call VUAssertEquals(mvom#renderer#DoPaintMatches(5,1,5,{},"UnpaintTestStub","PaintTestStub"),{})
	" if all lines are currently visible, don't do anything:
	" first just paint one line. We expect that the line '1' would be painted,
	" and that the highlight group is created (and 'mvom#test#test1plugin' is called).
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(mvom#renderer#DoPaintMatches(6,1,5,{1:{'count':1,'plugins':['mvom#test#test1plugin'],'line':1,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':1,'plugins':['mvom#test#test1plugin'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" two lines, implies some reconciliation should be happening here:
	unlet! g:mvom_hi_MVOM_000000000000
	let g:mv_plugins = []
	call mvom#renderer#add('mvom#test#test1plugin','mvom#test#nopaint')
	call mvom#renderer#add('mvom#test#test2plugin','mvom#test#rrpaint')
	call VUAssertEquals(mvom#renderer#DoPaintMatches(10,1,5,{1:{'count':1,'plugins':['mvom#test#test1plugin','mvom#test#test2plugin'],'line':1,'text':'XX','fg':'000000','bg':'000000'},2:{'count':1,'plugins':['mvom#test#test1plugin'],'line':2,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':2,'plugins':['mvom#test#test1plugin','mvom#test#test2plugin'],'line':2,'text':'RR','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(mvom#renderer#DoPaintMatches(10,6,10,{1:{'count':1,'plugins':['mvom#test#test1plugin'],'line':1,'text':'XX','fg':'000000','bg':'000000'},10:{'count':1,'plugins':['mvom#test#test1plugin'],'line':10,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{6:{'count':1,'plugins':['mvom#test#test1plugin'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':0},10:{'count':1,'plugins':['mvom#test#test1plugin'],'line':10,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" dubgging call
	" echo mvom#renderer#DoPaintMatches(line('$'),line('w0'),line('w$'),mvom#renderer#CombineData(g:mv_plugins),"UnpaintTestSign","PaintTestStub")

  " When a plugin is removed, it should not longer be in the list of plugins
	call mvom#renderer#remove('mvom#test#test2plugin')
  call VUAssertEquals(g:mv_plugins,[{ 'plugin': 'mvom#test#test1plugin', 'render': 'mvom#test#nopaint' }])
endfunction

"}}}

function! TestSuite()
	call TestCombineData()
  call TestConvertToPercentOffset()
	call TestDoPaintMatches()
	call TestGetHumanReadables()
	call TestGetSignName()
	call TestRGBToHSVAndBack()
	call TestHexToRGBAndBack()
	call TestUniq()
	call TestLoadRegisters()
endfunction

" call VURunnerRunTest('TestSuite')

" vim: set fdm=marker :
