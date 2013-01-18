" Show all changes of this file from the latest version checked into git.
" 
" Options:
"   - gitcommand: the full path to the git command. If not present it is
"     assumed to be in the path (and 'git' is used).

function! mvom#plugins#git#init(options)
endfunction

function! mvom#plugins#git#deinit()
endfunction

function! mvom#plugins#git#data(options)
  if !exists('b:mvom_gitfn')
    let b:mvom_gitfn = mvom#util#location#memoize(
          \function('mvom#plugins#git#search'),
          \function('mvom#plugins#git#memoizeByFileTick'))
  endif
  return b:mvom_gitfn.call(a:options)
endfunction

function! mvom#plugins#git#search(options)
  " parse the git diff -p output.
  "
  " for each line with a match return whether it is an addition or subtraction
  " TODO use a temp file

  " We want to see the git diff even for files that haven't been written yet.
  " To do that we need to write the un-saved file somewhere and diff that
  " against the version at the head of this repo:
  let directory = mvom#plugins#git#getdirectory(expand('%'))
  let filename = mvom#plugins#git#getfilename(expand('%'))
  let branch = mvom#plugins#git#getgitbranch(expand('%'))
  let prefix = mvom#plugins#git#getgitprefix(expand('%'))
  exec printf("silent! !cd %s && git show %s:%s%s > /tmp/aa.txt",
        \directory,
        \branch,
        \prefix,
        \filename)
  exec "silent! w! /tmp/bb.txt"

  " Do a unified diff of the two temp files to get our diff.
  exec "silent! !diff -u /tmp/aa.txt /tmp/bb.txt > /tmp/t.diff"
  if v:shell_error != 0
    " TODO memoize by the filetick.
    let diffs = mvom#plugins#git#ParsePatchFile('/tmp/t.diff')
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
function! mvom#plugins#git#getgitprefix(file)
  exe printf("silent! !cd %s ; git rev-parse --show-prefix > /tmp/git.txt",
        \mvom#plugins#git#getdirectory(a:file)
        \)
  return readfile('/tmp/git.txt')[0]
endfunction

function! mvom#plugins#git#getgitroot(file)
  exe printf("silent! !cd %s ; git rev-parse --show-toplevel > /tmp/git.txt",
        \mvom#plugins#git#getdirectory(a:file)
        \)
  return readfile('/tmp/git.txt')[0]
endfunction

function! mvom#plugins#git#getgitbranch(file)
  let cmd = printf('silent! !cd %s && git branch --no-color | grep "*" | sed "s/\* //" > /tmp/git.txt',
        \mvom#plugins#git#getdirectory(a:file)
        \)
  exec cmd
  return readfile('/tmp/git.txt')[0]
endfunction

function! mvom#plugins#git#getdirectory(file)
  if a:file =~ '\/'
    return substitute(a:file,'^\v(.+)\/[^\/]+$','\=submatch(1)','')
  else
    " no path found, must be in the current working directory:
    return '.'
  endif
endfunction

function! mvom#plugins#git#getfilename(file)
  return substitute(expand('%'),'\v^.*\/',"","")
endfunction

function! mvom#plugins#git#enabled(options)
  if expand('%') == ''
    return 0
  endif
  let filename = mvom#plugins#git#getfilename(expand('%'))
  let directory = mvom#plugins#git#getdirectory(expand('%'))
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
function! mvom#plugins#git#ParsePatchFile(filename)
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
function! mvom#plugins#git#memoizeByFileTick(args)
  " TODO changedtick sucks. I really want a hash of the file contents. That
  " would allow us to reuse contents when the user 'undos' something.
  " probably hooking in a filechange hook and doing a write to a temp file and
  " then hashing that temp file would do the trick. Over doing it? Maybe...
  return mvom#util#color#hash(string(b:changedtick))
endfunction

function! mvom#plugins#git#paint(options,vals)
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
	let added = mvom#renderers#util#TypicalPaint(filtered,a:options)

  " paint the removed lines
  let filtered['lines'] = {}
  for line in keys(a:vals['lines'])
    if has_key(a:vals['lines'][line],'removed')
      let filtered['lines'][line] = a:vals['lines'][line]
    endif
  endfor
  let a:options['chars'] = a:options['removedchar'] . a:options['removedchar'] 
  let a:options['color'] = a:options['removedcolor']
  let a:options['xchars'] = '/' . a:options['removedchar'] 
  let a:options['xcolor'] = a:options['removedcolor']
  let a:options['iconcolor'] = a:options['removedcolor']
	let removed = mvom#renderers#util#TypicalPaint(filtered,a:options)

  for line in keys(added['lines'])
    let removed['lines'][line] = added['lines'][line]
  endfor

  return removed
endfunction

function! mvom#plugins#git#reconcile(options,vals,plugin)
  " do the same slash paint, but once with additions, once with subtractions
  return mvom#renderers#slash#reconcile(a:options,a:vals,a:plugin)
endfunction
