" Logic that creates a PNG that can be put into the signs gutter.

" Add a rectangle to the final image.
function! mvom#renderers#icon#addRectangle(image,color,x,y,width,height)
  call add(a:image['data'],'<rect x="'. a:x .'" y="'. a:y .'" height="'. a:height .'" width="'. a:width .'" style="fill: #'. a:color .';"/>')
endfunction

" Make a new Image dictionary - used by #add and #generateFile, etc.
function! mvom#renderers#icon#makeImage()
  let results = {}
  let results['data'] = []
  return results
endfunction

" Given an image object (mvom#renderers#icon#makeImage), return a string of the XPM.
function! mvom#renderers#icon#generateSVG(image)
  let data = '<svg width="50px" height="50px">'
  for i in a:image['data']
    let data = data . i
  endfor
  return data .'</svg>'
endfunction

function! mvom#renderers#icon#generatePNGFile(image,name)
  let convert = 'convert'
  let cachefolder = expand('~/.vim/mvom-cache')
  exec "silent ! mkdir -p ". cachefolder
  call writefile([mvom#renderers#icon#generateSVG(a:image)], cachefolder ."/". a:name .".svg")
  exec "silent ! ". convert ." ". cachefolder ."/". a:name .".svg ". cachefolder ."/". a:name .".png"
endfunction
