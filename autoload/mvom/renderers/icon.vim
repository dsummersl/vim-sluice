" Logic that creates a PNG that can be put into the signs gutter.

" Add a rectangle to the final image.
function! mvom#renderers#icon#addRectangle(color,x,y,width,height) dict
  call add(self.data,'<rect x="'. a:x .'" y="'. a:y .'" height="'. a:height .'" width="'. a:width .'" style="fill: #'. a:color .';"/>')
endfunction

" Add a rectangle with alignment properties
" - color: the color
" -     y: y
" - width: an integer. Percent of the width to take up.
" - height: pixels height. an integer.
" - align: left|center|right where to align the line to.
function! mvom#renderers#icon#placeRectangle(color,y,width,height,align) dict
  let pixwidth = float2nr(a:width / 100.0 * 50)
  let startpoint = 0
  if a:align == 'left'
    let startpoint = 0
  elseif a:align == 'right'
    let startpoint = 50 - pixwidth
  elseif a:align == 'center'
    let startpoint = float2nr((50-pixwidth)/2)
  else
    throw "Unknown alignment '". a:align ."'. Must be one of: left, right, center."
  endif
  call add(self.data,'<rect x="'. startpoint .'" y="'. a:y .'" height="'. a:height .'" width="'. pixwidth .'" style="fill: #'. a:color .';"/>')
endfunction

" Make a new Image dictionary - used by #add and #generateFile, etc.
function! mvom#renderers#icon#makeImage()
  let results = { 'data': [],
        \'addRectangle': function('mvom#renderers#icon#addRectangle'),
        \'placeRectangle': function('mvom#renderers#icon#placeRectangle'),
        \'generateSVG': function('mvom#renderers#icon#generateSVG'),
        \'generatePNGFile': function('mvom#renderers#icon#generatePNGFile')
        \}
  let results['data'] = []
  return results
endfunction

" Given an image object (mvom#renderers#icon#makeImage), return a string of the XPM.
function! mvom#renderers#icon#generateSVG() dict
  let data = '<svg width="50px" height="50px">'
  for i in self.data
    let data = data . i
  endfor
  return data .'</svg>'
endfunction

function! mvom#renderers#icon#generatePNGFile(name) dict
  let convert = 'convert'
  let cachefolder = expand('~/.vim/mvom-cache')
  exec "silent ! mkdir -p ". cachefolder
  call writefile([self.generateSVG()], cachefolder ."/". a:name .".svg")
  exec "silent ! ". convert ." ". cachefolder ."/". a:name .".svg ". cachefolder ."/". a:name .".png"
endfunction
