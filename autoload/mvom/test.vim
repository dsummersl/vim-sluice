" test functions {{{

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

function! Test1Enabled()
	return 1
endfunction
function! Test1Data()
	return {}
endfunction
function! Test1Init()
endfunction
function! Test2Data()
	return {'1':{'count':1}}
endfunction
function! Test2Init()
endfunction
function! Test2Enabled()
	return 1 
endfunction
function! Test3Data()
	return {'1':{'count':1},'2':{'count':2}}
endfunction
function! Test3Init()
endfunction
function! Test3Enabled()
	return 1 
endfunction
function! Test4Data()
	return {'1':{'count':1,'isvis':1},'2':{'count':2}}
endfunction
function! Test4Init()
endfunction
function! Test4Enabled()
	return 1 
endfunction
function! Test5Data()
	return {'5':{'count':1},'6':{'count':2}}
endfunction
function! Test5Init()
endfunction
function! Test5Enabled()
	return 1
endfunction
function! Test1Paint(data)
	return {}
endfunction
function! Test2Paint(data)
	return {'1':{'text':'..', 'fg':'testhi', 'bg':'testbg'}}
endfunction
function! Test3Paint(data)
	let results = {}
	for line in keys(a:data)
		let results[line] = copy(a:data[line])
		let results[line]['fg'] = 'testhi'
		let results[line]['bg'] = 'testbg'
		let results[line]['text'] = '..'
	endfor
	return results
endfunction

function! TestCombineData()
  " put your curser in this block somewhere and then type ":call VUAutoRun()"
	" TODO these are still NOT passing.
	let w:save_cursor = winsaveview()
	call VUAssertEquals(CombineData([{'plugin':'Test1','render':'Test1'}]),{})
	call VUAssertEquals(CombineData([{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(CombineData([{'plugin':'Test1','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	call VUAssertEquals(CombineData([{'plugin':'Test2','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test2'], 'line':1, 'bg':'testbg'}})
	" expect line 1 to have count=2 and then a line 2 of count 2
	" but then just the rendering for test2 will happen so...same old thing
	" there.
	call VUAssertEquals(CombineData([{'plugin':'Test3','render':'Test1'},{'plugin':'Test2','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test3','Test2'], 'line':1, 'bg':'testbg'}})
	" if one data source has an extra key it should always be in the results
	" regardless of order:
	call VUAssertEquals(CombineData([{'plugin':'Test4','render':'Test2'},{'plugin':'Test3','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test4','Test3'], 'line':1, 'bg':'testbg', 'isvis':1}})
	call VUAssertEquals(CombineData([{'plugin':'Test3','render':'Test2'},{'plugin':'Test4','render':'Test2'}]),{'1':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test3','Test4'], 'line':1, 'bg':'testbg', 'isvis':1}})
	" non intersecting data sets, both should be there.
	call VUAssertEquals(CombineData([{'plugin':'Test4','render':'Test3'},{'plugin':'Test5','render':'Test3'}]), { '1':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test4'], 'line':1, 'bg':'testbg', 'isvis':1}, '2':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test4'], 'line':2, 'bg':'testbg'}, '5':{'count':1, 'text':'..', 'fg':'testhi', 'plugins':['Test5'], 'line':5, 'bg':'testbg'}, '6':{'count':2, 'text':'..', 'fg':'testhi', 'plugins':['Test5'], 'line':6, 'bg':'testbg'}, })
endfunction

function! TestConvertToPercentOffset()
  " put your curser in this block somwhere and then type ":call VUAutoRun()"
  call VUAssertEquals(mvom#util#ConvertToPercentOffset(1,1,31,31),1)
  call VUAssertEquals(mvom#util#ConvertToPercentOffset(31,1,31,31),31)
  call VUAssertEquals(mvom#util#ConvertToPercentOffset(1,70,100,100),70)
  call VUAssertEquals(mvom#util#ConvertToPercentOffset(100,70,100,100),100)
  call VUAssertEquals(mvom#util#ConvertToPercentOffset(50,70,100,100),85)
endfunction

function! TestGetHumanReadables()
	call VUAssertEquals(mvom#util#GetHumanReadables(""),"")
	call VUAssertEquals(mvom#util#GetHumanReadables("aa"),"aa")
	call VUAssertEquals(mvom#util#GetHumanReadables(".."),"dtdt")
	call VUAssertEquals(mvom#util#GetHumanReadables("\\\\"),"bsbs")
	call VUAssertEquals(mvom#util#GetHumanReadables("//"),"fsfs")
	call VUAssertEquals(mvom#util#GetHumanReadables("--"),"dada")
endfunction

function! TestGetSignName()
	call VUAssertEquals(mvom#util#color#GetSignName({'fg':'000000','bg':'111111','text':'--'}),"MVOM_000000111111_dada")
endfunction

function! PaintTestStub(line,onscreen)
endfunction
function! UnpaintTestStub(line)
endfunction
function! NoReconcile(data)
	return a:data " do nothing
endfunction
function! RRReconcile(data)
	" change it to 'R' for reconcile?
	let a:data['text'] = 'RR'
	return a:data
endfunction

function! TestDoPaintMatches()
	call VUAssertEquals(DoPaintMatches(5,1,5,{},"UnpaintTestStub","PaintTestStub"),{})
	" if all lines are currently visible, don't do anything:
	" first just paint one line. We expect that the line '1' would be painted,
	" and that the highlight group is created (and 'Test1' is called).
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(DoPaintMatches(6,1,5,{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" two lines, implies some reconciliation should be happening here:
	unlet! g:mvom_hi_MVOM_000000000000
	let g:mv_plugins = []
	call MVOM_Setup('Test1','No')
	call MVOM_Setup('Test2','RR')
	call VUAssertEquals(DoPaintMatches(10,1,5,{1:{'count':1,'plugins':['Test1','Test2'],'line':1,'text':'XX','fg':'000000','bg':'000000'},2:{'count':1,'plugins':['Test1'],'line':2,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{1:{'count':2,'plugins':['Test1','Test2'],'line':2,'text':'RR','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	unlet! g:mvom_hi_MVOM_000000000000
	call VUAssertEquals(DoPaintMatches(10,6,10,{1:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000'},10:{'count':1,'plugins':['Test1'],'line':10,'text':'XX','fg':'000000','bg':'000000'}},"UnpaintTestStub","PaintTestStub"),{6:{'count':1,'plugins':['Test1'],'line':1,'text':'XX','fg':'000000','bg':'000000','visible':0},10:{'count':1,'plugins':['Test1'],'line':10,'text':'XX','fg':'000000','bg':'000000','visible':1}})
	call VUAssertEquals(exists("g:mvom_hi_MVOM_000000000000"),1)
	" dubgging call
	" echo DoPaintMatches(line('$'),line('w0'),line('w$'),CombineData(g:mv_plugins),"UnpaintTestSign","PaintTestStub")
endfunction

function! TestUniq()
	call VUAssertEquals(<SID>Uniq([]),[])
	call VUAssertEquals(<SID>Uniq([1,2,3]),[1,2,3])
	call VUAssertEquals(<SID>Uniq([3,2,1]),[3,2,1])
	call VUAssertEquals(<SID>Uniq([3,2,1,2,3]),[3,2,1])
	call VUAssertEquals(<SID>Uniq(['onea','oneb','onea']),['onea','oneb'])
endfunction

function! TestLoadRegisters()
	let from = "something"
	let @8 = from
	let registers = mvom#util#SaveRegisters()
	call VUAssertEquals(from,registers["reg-8"])
	let registers["reg-8"] = from ."2"
	call mvom#util#LoadRegisters(registers)
	call VUAssertEquals(from ."2",@8)
endfunction

function! TestSuite()
"call VURunnerRunTest('TestSuite')
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
"}}}
