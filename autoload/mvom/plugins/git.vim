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
  exec printf("silent !cd %s && git show %s:%s%s > /tmp/aa.txt",
        \directory,
        \branch,
        \prefix,
        \filename)
  exec "silent !w! /tmp/bb.txt"

  " Do a unified diff of the two temp files to get our diff.
  exec "silent !diff -u /tmp/aa.txt /tmp/bb.txt > /tmp/t.diff"
  if !v:shell_error
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
  let dir = ''
  redir => dir
  exe printf("silent! !cd %s ; git rev-parse --show-prefix",
        \mvom#plugins#git#getdirectory(a:file)
        \)
  redir END
  return s:lastwordonly(dir)
endfunction

function! mvom#plugins#git#getgitroot(file)
  let gitroot = ''
  redir => gitroot
  exe printf("silent! !cd %s ; git rev-parse --show-toplevel",
        \mvom#plugins#git#getdirectory(a:file)
        \)
  redir END
  return s:lastwordonly(gitroot)
endfunction

function! mvom#plugins#git#getgitbranch(file)
  let cmd = printf('silent! !cd %s && git branch --no-color | grep "*" | sed "s/\* //"',
        \mvom#plugins#git#getdirectory(a:file)
        \)
  echom cmd
  redir => gitbranch
  exec cmd
  redir END
  return s:lastwordonly(gitbranch)
endfunction

function! mvom#plugins#git#getdirectory(file)
  if a:file =~ '\/'
    return substitute(a:file,'^\v(.+)\/[^\/]+$','\=submatch(1)','')
  else
    " no path found, must be in the current working directory:
    return '.'
  endif
endfunction

" The cmd output includes the command itself and a bunch of control
" characters. This just returns the last interesting bit of data:
function! s:lastwordonly(output)
  let lastline = ''
  for line in split(a:output,'\r')
    let line = substitute(line,'^\v([^ ]+).*','\=submatch(1)','')
    let line = substitute(line,'\%x00','','')
    if len(line) > 0
      let lastline = line
    endif
  endfor
  return lastline
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
