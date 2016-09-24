" Logic that creates a PNG that can be put into the signs gutter.

" Make a new Image dictionary - used by #add and #generateFile, etc.
" Parameters:
" - width    : the width in pixels. defaults to 50.
" - height   : the height in pixels. defaults to 50.
function! sluice#renderers#icon#makeImage(...)
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
  " 'svg' is the actual svg string
  " 'data' is the boundary points of the corresponding svg element.
  let results = { 'svg': [], 'data': [],
        \'width': width,
        \'height': height,
        \'addRectangle': function('sluice#renderers#icon#addRectangle'),
        \'addText': function('sluice#renderers#icon#addText'),
        \'placeRectangle': function('sluice#renderers#icon#placeRectangle'),
        \'generateHash': function('sluice#renderers#icon#generateHash'),
        \'generateSVG': function('sluice#renderers#icon#generateSVG'),
        \'generatePNGFile': function('sluice#renderers#icon#generatePNGFile')
        \}
  let results['svg'] = []
  return results
endfunction

" Generate a hash of this image. 
"
" You can optionally include 4 additional parameters that
" correspond to a translations and clip:
" - x
" - y
" - width
" - height
"
" With the optional attributes only the specific characters within the
" hash are considered when generating the hash.
function! sluice#renderers#icon#generateHash(...) dict
  if exists('a:1')
    let matches = ''
    for d in self.data
      " find all the elements that intersect this boundary area
      " http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
      let ax1 = d['x']
      let ax2 = d['x'] + d['width']
      let ay1 = d['y']
      let ay2 = d['y'] + d['height']
      let bx1 = a:1
      let bx2 = a:1 + a:3 - 1
      let by1 = a:2
      let by2 = a:2 + a:4 - 1
      if ax1 <= bx2 && ax2 >= bx1 && ay1 <= by2 && ay2 >= by1
        " only add the portion that is in the clip:
        let cp = copy(d)
        " if we are matching bottom or top ends we want to differentiate
        " between normal old matches so that we don't miss any styling (rx...)
        let topclip = ''
        let botclip = ''
        if ax1 <= bx1 | let cp['x'] = bx1 | endif
        if ax2 >= bx2 | let cp['width'] = bx2-bx1 | endif

        if ay1 <= by1 | let topclip = 'tc' | endif
        if ay1 <= by1 | let cp['y'] = by1 | endif

        if ay2 >= by2 | let botclip = 'bc' | endif
        if ay2 >= by2 | let cp['height'] = by2-by1 | endif

        let cp['x'] = cp['x'] % a:3
        let cp['y'] = cp['y'] % a:4
        let matches = matches . topclip . string(cp) . botclip
      endif
    endfor
    " call VULog( "_#hash = ". matches ." = ". _#hash(matches))
    return _#hash(matches)
  else
    return _#hash(self.generateSVG())
  endif
endfunction

" Given an image object (sluice#renderers#icon#makeImage), return a string of the XPM.
"
" You can optionally include 4 additional parameters that
" correspond to a translations and clip:
" - x
" - y
" - width
" - height
function! sluice#renderers#icon#generateSVG(...) dict
  if exists('a:1')
    let svg = '<svg width="'. (a:3+1) .'px" height="'. a:4 .'px">'
    let svg = svg . printf('<g transform="translate(%d,%d)">',-a:1,-a:2)
  else
    let svg = '<svg width="'. self.width .'px" height="'. self.height .'px">'
  endif

  for i in self.svg
    let svg = svg . i
  endfor

  if exists('a:1')
    let svg = svg .'</g>'
  endif

  return svg .'</svg>'
endfunction

" Generate a PNG file.
"
" Arguments:
" - name: the file name (absolute path)
" 
" You can optionally include 4 additional parameters that
" correspond to a translations and clip:
" - x
" - y
" - width
" - height
function! sluice#renderers#icon#generatePNGFile(name,...) dict
  let convert = g:sluice_convert_command
  if exists('a:1')
    let x = a:1
    let y = a:2
    let w = a:3
    let h = a:4
    call writefile([self.generateSVG(x,y,w,h)], a:name .".svg")
  else
    call writefile([self.generateSVG()], a:name .".svg")
  endif
  exec printf("silent ! %s %s.svg %s.png && rm %s.svg",convert,a:name,a:name,a:name)
endfunction

" Add a rectangle to the final image.
"
" Optional Parameters:
" - style: string to go into the svg style area
" - params: extra <rect> keys (ie, rx,ry)
function! sluice#renderers#icon#addRectangle(color,x,y,width,height,...) dict
  let style=''
  if exists('a:1')
    let style = a:1
  endif
  let extra=''
  if exists('a:2')
    let extra = a:2
  endif
  call add(self.svg,printf('<rect x="%d" y="%d" height="%d" width="%d" style="fill: #%s;%s" %s/>',a:x, a:y, a:height, a:width, a:color, style, extra))
  call add(self.data,{ 'x': a:x, 'y': a:y, 'width': a:width, 'height': a:height, 'type': 'rect', 'color': a:color, 'style': style, 'extra':extra})
endfunction

" Place text. The x/y location correspond to the lower right corner of the
" bounding box for the text. Only one character fits reliably on a line but...
" one could easily shrink things down by messing with the font-size attribute.
"
" Optional Parameters:
" - style: string to go into the svg style area
function! sluice#renderers#icon#addText(text,color,x,y,...) dict
  " TODO use a monospace font.
  let style=''
  if exists('a:1')
    let style = a:1
  endif
  call add(self.svg,printf('<text x="%d" y="%d" fill="%s" text-anchor="end" font-size="9" style="%s">%s</text>',a:x,a:y,a:color,style,a:text))
  " TODO this doesn't properly define the boundary for 'g' and the like.
  call add(self.data,{ 'x': a:x-len(a:text)*4, 'y': a:y-9, 'width': len(a:text)*4, 'height': 9, 'type': 'text', 'color': a:color, 'text': a:text, 'style': style })
endfunction

" Add a rectangle with alignment properties
" - color: the color
" -     y: y
" - width: an integer. Percent of the width to take up.
" - height: pixels height. an integer.
" - align: left|center|right where to align the line to.
"
" Optional Parameters:
" - style: string to go into the svg style area
" - params: extra <rect> keys (ie, rx,ry)
function! sluice#renderers#icon#placeRectangle(color,y,width,height,align,...) dict
  let style=''
  if exists('a:1')
    let style = a:1
  endif
  let extra=''
  if exists('a:2')
    let extra = a:2
  endif
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
  call add(self.svg,printf('<rect x="%d" y="%d" height="%d" width="%d" style="fill: #%s;%s" %s/>',startpoint, a:y, a:height, pixwidth, a:color, style,extra))
  call add(self.data,{ 'x': startpoint, 'y': a:y, 'width': pixwidth, 'height': a:height, 'type': 'rect', 'color': a:color, 'style': style, 'extra': extra})
endfunction
