" Show all changes of this file from the latest version checked into git.
" 
" Options:
"   - gitcommand: the full path to the git command. If not present it is
"     assumed to be in the path (and 'git' is used).

function! mvom#plugins#search#init(options)
endfunction

function! mvom#plugins#git#deinit()
endfunction

function! mvom#plugins#git#data(options)
  " determine if the current file is under git control.
  " cd % && git ls-files file_name --error-unmatch
  "
  " parse the git diff -p output.
  "
  " for each line with a match return whether it is an addition or subtraction
endfunction

function! mvom#plugins#git#enabled(options)
  " cd % && git ls-files file_name --error-unmatch
  " TODO and...is the file under version control?
  return &hls == 1
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
