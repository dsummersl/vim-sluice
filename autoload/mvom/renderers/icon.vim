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
  let pixwidth = float2nr(a:width / 100.0 * self.width)
  let startpoint = 0
  if a:align == 'left'
    let startpoint = 0
  elseif a:align == 'right'
    let startpoint = self.width - pixwidth
  elseif a:align == 'center'
    let startpoint = float2nr((self.width-pixwidth)/2)
  else
    throw "Unknown alignment '". a:align ."'. Must be one of: left, right, center."
  endif
  call add(self.data,'<rect x="'. startpoint .'" y="'. a:y .'" height="'. a:height .'" width="'. pixwidth .'" style="fill: #'. a:color .';"/>')
endfunction

" Make a new Image dictionary - used by #add and #generateFile, etc.
" Parameters:
" - width    : the width in pixels. defaults to 50.
" - height   : the height in pixels. defaults to 50.
function! mvom#renderers#icon#makeImage(...)
  if exists('a:1')
    let width = a:1
  else
    let width = 50
  endif
  if exists('a:2')
    let height = a:2
  else
    let height = 50
  endif
  let results = { 'data': [],
        \'width': width,
        \'height': height,
        \'cachedir': '/Users/danesummers/.vim/mvom-cache/',
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
  let data = '<svg width="'. self.width .'px" height="'. self.height .'px">'
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
