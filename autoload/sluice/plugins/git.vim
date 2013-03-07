" Show all changes of this file from the latest version checked into git.
" 
" Options:
"   - gitcommand: the full path to the git command. If not present it is
"     assumed to be in the path (and 'git' is used).
"
" TODO respect ignore whitespace

function! sluice#plugins#git#init(options)
endfunction

function! sluice#plugins#git#deinit()
endfunction

function! sluice#plugins#git#data(options)
  if !exists('b:sluice_gitfn')
    let b:sluice_gitfn = _#memoize(
          \function('sluice#plugins#git#search'),
          \function('sluice#plugins#git#memoizeByFileTick'))
  endif
  return b:sluice_gitfn.call(a:options)
endfunction

function! sluice#plugins#git#search(options)
  " parse the git diff -p output.
  "
  " for each line with a match return whether it is an addition or subtraction
  " TODO use a temp file

  " We want to see the git diff even for files that haven't been written yet.
  " To do that we need to write the un-saved file somewhere and diff that
  " against the version at the head of this repo:
  let directory = sluice#plugins#git#getdirectory(expand('%'))
  let filename = sluice#plugins#git#getfilename(expand('%'))
  let branch = sluice#plugins#git#getgitbranch(expand('%'))
  let prefix = sluice#plugins#git#getgitprefix(expand('%'))
  exec printf("silent! !cd %s && git show %s:%s%s > /tmp/aa.txt",
        \directory,
        \branch,
        \prefix,
        \filename)
  exec "silent! w! /tmp/bb.txt"

  " Do a unified diff of the two temp files to get our diff.
  exec "silent! !diff -u /tmp/aa.txt /tmp/bb.txt > /tmp/t.diff"
  if v:shell_error != 0
    let diffs = sluice#plugins#git#ParsePatchFile('/tmp/t.diff')
    return { 'lines': diffs }
  else
    echom 'Unable to diff aa/bb: '. v:shell_error
    return { 'lines': {} }
  endif
endfunction

" Show the relative path of a file within the git repo.
"
" Example:
" a file is in include/file.txt
" this function would return include/
function! sluice#plugins#git#getgitprefix(file)
  exe printf("silent! !cd %s ; git rev-parse --show-prefix > /tmp/git.txt",
        \sluice#plugins#git#getdirectory(a:file)
        \)
  return readfile('/tmp/git.txt')[0]
endfunction

function! sluice#plugins#git#getgitroot(file)
  exe printf("silent! !cd %s ; git rev-parse --show-toplevel > /tmp/git.txt",
        \sluice#plugins#git#getdirectory(a:file)
        \)
  return readfile('/tmp/git.txt')[0]
endfunction

function! sluice#plugins#git#getgitbranch(file)
  let cmd = printf('silent! !cd %s && git branch --no-color | grep "*" | sed "s/\* //" > /tmp/git.txt',
        \sluice#plugins#git#getdirectory(a:file)
        \)
  exec cmd
  return readfile('/tmp/git.txt')[0]
endfunction

function! sluice#plugins#git#getdirectory(file)
  if a:file =~ '\/'
    return substitute(a:file,'^\v(.+)\/[^\/]+$','\=submatch(1)','')
  else
    " no path found, must be in the current working directory:
    return '.'
  endif
endfunction

function! sluice#plugins#git#getfilename(file)
  return substitute(expand('%'),'\v^.*\/',"","")
endfunction

function! sluice#plugins#git#enabled(options)
  if expand('%') == ''
    return 0
  endif
  let filename = sluice#plugins#git#getfilename(expand('%'))
  let directory = sluice#plugins#git#getdirectory(expand('%'))
  " is the file under version control?
  exec printf("silent !cd %s && git ls-files %s --error-unmatch",directory,filename)
  return v:shell_error == 0
endfunction

" Parse a file of a patch file.
"
" Returns:
"   A dictionary of with keys:
"    - lines:
"      removed: equal to true if the line was removed.
"      added: equal to true if the line was added.
function! sluice#plugins#git#ParsePatchFile(filename)
  let results = {}
  let foundDiffSection = 0
  let offset = 0
  for line in readfile(a:filename)
    if line =~ '^@@'
      let foundDiffSection = 1
      let matches = matchlist(line,'^@@\v -(\d+),(\d+) \+(\d+),(\d+)\m @@')
      if len(matches) > 0
        let offset = matches[1]
      endif
    elseif foundDiffSection
      if line =~ '^+'
        if !has_key(results,offset) | let results[offset] = {} | endif
        let results[offset]['added'] = 1
        let offset += 1
      elseif line =~ '^-'
        if !has_key(results,offset) | let results[offset] = {} | endif
        let results[offset]['removed'] = 1
      else
        let offset += 1
      endif
    endif
  endfor
  return results
endfunction

" A memoization function for the git data function.
" Memoizes by the file tick only.
function! sluice#plugins#git#memoizeByFileTick(args)
  " TODO changedtick sucks. I really want a hash of the file contents. That
  " would allow us to reuse contents when the user 'undos' something.
  " probably hooking in a filechange hook and doing a write to a temp file and
  " then hashing that temp file would do the trick. Over doing it? Maybe...
  return _#hash(string(b:changedtick))
endfunction

function! sluice#plugins#git#paint(options,vals)
  " We need two paint operations - one with the additions, one with the
  " subtractions
  let filtered = { 'lines': {},
        \'gutterImage': a:vals['gutterImage'],
        \'pixelsperline': a:vals['pixelsperline'],
        \}
  for line in keys(a:vals['lines'])
    if has_key(a:vals['lines'][line],'added')
      let filtered['lines'][line] = a:vals['lines'][line]
    endif
  endfor
  let a:options['chars'] = a:options['addedchar'] . a:options['addedchar'] 
  let a:options['color'] = a:options['addedcolor']
  let a:options['xchars'] = '/' . a:options['addedchar'] 
  let a:options['xcolor'] = a:options['addedcolor']
  let a:options['iconcolor'] = a:options['addedcolor']
	let added = sluice#renderers#util#TypicalPaint(filtered,a:options)

  " paint the removed lines
  let filtered['lines'] = {}
  for line in keys(a:vals['lines'])
    " only paint removed lines that aren't part of an addition (otherwise you
    " see add next to remove sometimes when really there was just an addition
    " going on there.
    if has_key(a:vals['lines'][line],'removed') && !has_key(a:vals['lines'][line],'added') 
      let filtered['lines'][line] = a:vals['lines'][line]
    endif
  endfor
  let a:options['chars'] = a:options['removedchar'] . a:options['removedchar'] 
  let a:options['color'] = a:options['removedcolor']
  let a:options['xchars'] = '/' . a:options['removedchar'] 
  let a:options['xcolor'] = a:options['removedcolor']
  let a:options['iconcolor'] = a:options['removedcolor']
	let removed = sluice#renderers#util#TypicalPaint(filtered,a:options)

  for line in keys(added['lines'])
    let removed['lines'][line] = added['lines'][line]
  endfor

  return removed
endfunction

function! sluice#plugins#git#reconcile(options,vals,plugin)
  " We need to look thru the plugins, and re-set the colors/chars depending on
  " the type of git match we had (add or delete)
  for p in a:vals
    if p.plugin == 'sluice#plugins#git'
      if has_key(p,'added')
        let a:options['chars'] = a:options['addedchar'] . a:options['addedchar'] 
        let a:options['color'] = a:options['addedcolor']
        let a:options['xchars'] = '/' . a:options['addedchar'] 
        let a:options['xcolor'] = a:options['addedcolor']
        let a:options['iconcolor'] = a:options['addedcolor']
      else
        let a:options['chars'] = a:options['removedchar'] . a:options['removedchar'] 
        let a:options['color'] = a:options['removedcolor']
        let a:options['xchars'] = '/' . a:options['removedchar'] 
        let a:options['xcolor'] = a:options['removedcolor']
        let a:options['iconcolor'] = a:options['removedcolor']
      endif
      break
    endif
  endfor
  return sluice#renderers#slash#reconcile(a:options,a:vals,a:plugin)
endfunction
