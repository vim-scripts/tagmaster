let g:tagmaster_addupdate = 1
let g:tagmaster_enable_autotags = 0
let g:tagmaster_options = "--fields=+iaS --extra=+q --c-kinds=+pd --c++-kinds=+pd"
let g:tagmaster_recursive = 1

augroup autotags

au autotags FileType c au autotags BufWritePost <buffer> call tagmaster#AutoUpdate()
au autotags FileType cpp au autotags BufWritePost <buffer> call tagmaster#AutoUpdate()

com! -complete=file -nargs=* TGenerate call tagmaster#GenTagsForProject(<f-args>)
com! -complete=file -nargs=* TUpdate call tagmaster#GenTagsForFile(<f-args>)
com! -complete=file -nargs=* TDelete call tagmaster#DelTagsForFile(<f-args>)
com! -complete=file -nargs=* TGen call tagmaster#GenTagsForProject(<f-args>)
com! -complete=file -nargs=* TUp call tagmaster#GenTagsForFile(<f-args>)
com! -complete=file -nargs=* TDel call tagmaster#DelTagsForFile(<f-args>)

function! tagmaster#GetFilesForType()
  let recurse = g:tagmaster_recursive
  let ext = g:extensions[&filetype]
  let line = ""
  for mask in ext
    let line = line . mask . " " . (recurse ? "**/" . mask . " " : "")
  endfor
  return line
endfunction

function! tagmaster#GenTagsForProject(...)
  let recurse = g:tagmaster_recursive
  let extra_args = " "
  for arg in a:000
    if arg == '-recurse'
      let g:tagmaster_recursive = 1
    elseif arg == '-norecurse'
      let g:tagmaster_recursive = 0
    elseif arg == '-append'
      let extra_args = extra_args . " -a"
    else
      let extra_args = extra_args . " -f '" . arg . "'"
    endif
  endfor
  let files = tagmaster#GetFilesForType()

  exe("silent! !ctags --tag-relative=yes".extra_args." ".g:tagmaster_options." ".files)
  let g:tagmaster_recursive = recurse
endfunction

function! tagmaster#DelTagsForFile(...)
  let fname = expand(expand("%"))
  if a:0 > 0
    let fname = a:1
  endif
  if a:0 > 1
    call tagmaster#Delete(fname, a:2)
  else
    call tagmaster#Delete(fname)
  endif
endfunction

function! tagmaster#GenTagsForFile(...)
  let fname = ""
  let tagsname = ""
  let allowadd = g:tagmaster_addupdate
  for arg in a:000
    if arg == '-noadd'
      let allowadd = 0
    elseif arg == '-add'
      let allowadd = 1
    elseif fname == ""
      let fname = arg
    else
      let tagsname = arg
    endif
  endfor
  if fname == ""
    let fname = expand(expand("%"))
  endif
  if tagsname == ""
    if allowadd == 1
      call tagmaster#MakeTags(fname)
    else
      call tagmaster#Update(fname)
    endif
  else
    if allowadd == 1
      call tagmaster#MakeTags(fname, tagsname)
    else
      call tagmaster#Update(fname, tagsname)
    endif
  endif
endfunction

" Returns the name of tags file for current project. Returns 0 if doesn't
" exist.
function! tagmaster#Exists(...)
  let tagfiles = tagfiles()

  let fname = expand(expand("%"))

  if a:0 > 0
    let fname = expand(a:1)
  endif

  for tagfile in l:tagfiles
    let l:expandto = ":p:h"
    while fnamemodify(fname, l:expandto) != '/'
      if (substitute(tagfile, fnamemodify(fname, l:expandto)."/", "", "") == fnamemodify(tagfile, ":p:t"))
        return tagfile
      endif
      let expandto = expandto . ":h"
    endwhile
  endfor
  return ""
endfunction

" Generates tags or given file. Creates tags file if doesn't exist.
function! tagmaster#MakeTags(...)
  if a:0 > 0
    if a:0 > 1
      let l:tagfile = a:2
    else
      let l:tagfile = tagmaster#Exists(a:1)
    endif
  else
    let l:tagfile = tagmaster#Exists()
  endif

  if l:tagfile == ""
    call tagmaster#Create()
    let l:tagfile = tagmaster#Exists()
  endif

  if !filereadable(l:tagfile)
    call tagmaster#Create(l:tagfile)
  endif

  if a:0 > 0
    call tagmaster#Generate(a:1, l:tagfile)
  else
    call tagmaster#Generate()
  endif
endfunction

" Creates tag file for current project. Gives error if file already exists.
function! tagmaster#Create(...)
  let l:tagfile = tagmaster#Exists()

  if a:0 > 0
    let l:tagfile = a:1
  endif

  if l:tagfile != "" && filereadable(l:tagfile)
    echohl vimError
    echo "Error: tags file already exists!"
    return
  endif

  if l:tagfile == ""
    exe("silent! !ctags --tag-relative=yes -a ".g:tagmaster_options." ''")
  else
    exe("silent! !ctags --tag-relative=yes -a -f '".l:tagfile."' ".g:tagmaster_options." ''")
  endif
endfunction

function! tagmaster#AutoUpdate()
  if g:tagmaster_enable_autotags == 0
    return
  endif

  tagmaster#Update()
endfunction

" Update tags for current file. Doesn't add tags for current file if there
" weren't.
" Specially for auto update tags on write.
function! tagmaster#Update(...)
  let tagfiles = tagfiles()
  let fname = expand("%")
  if a:0 > 1
    let tagfiles = [a:2]
    let fname = a:1
  elseif a:0 > 0
    let fname = a:1
  endif

  let fname = fnamemodify(expand(fname), ":p")

  for tagfile in l:tagfiles
    let tagfile = fnamemodify(expand(tagfile), ":p")
    let file = tagmaster#RelFName(fname, tagfile)

    exe("silent! vimgrep /\<".escape(file, "\.\\")."\>/jg ".tagfile)

    let lst = getqflist()
    if 0 && len(lst)
      exe("silent! !grep -v -E -e'[[:blank:]]".file."[[:blank:]]' ".tagfile.">".tagmaster#TmpFName(l:tagfile))
      exe("silent! !ctags --tag-relative=yes -a -f ".tagmaster#TmpFName(l:tagfile)." ".g:tagmaster_options." ".expand("%"))
      exe("silent! !mv -f ".tagmaster#TmpFName(l:tagfile)." ".tagfile."")
      return
    endif
  endfor
endfunction

" Generate tags for current file. Use first available tags file.
function! tagmaster#Generate(...)
  let l:filename = expand("%")
  if a:0 > 0
    if a:0 > 1
      let l:tagfile = a:2
    else
      let l:tagfile = tagmaster#Exists(a:1)
      let l:filename = a:1
    endif
  else
    let l:tagfile = tagmaster#Exists()
  endif

  if l:tagfile != ""
    exe("silent! !grep -v -e'[[:blank:]]".tagmaster#RelFName(l:filename, tagfile)."[[:blank:]]' ".l:tagfile.">".tagmaster#TmpFName(l:tagfile))
    exe("silent! !ctags --tag-relative=yes -a -f".tagmaster#TmpFName(l:tagfile)." ".g:tagmaster_options." ".l:filename)
    exe("silent! !mv -f ".tagmaster#TmpFName(l:tagfile)." ".l:tagfile."")
    return
  endif

  echohl vimError
  echo "Error: No tag files found!"
endfunction

" Remove all tags for current file. Use first available tags file.
function! tagmaster#Delete(...)
  let l:filename = expand("%")
  if a:0 > 0
    if a:0 > 1
      let l:tagfile = a:2
    else
      let l:tagfile = tagmaster#Exists(a:1)
      let l:filename = a:1
    endif
  else
    let l:tagfile = tagmaster#Exists()
  endif

  if l:tagfile != ""
    exe("silent! !grep -v -e'[[:blank:]]".tagmaster#RelFName(l:filename, tagfile)."[[:blank:]]' ".l:tagfile.">".tagmaster#TmpFName(l:tagfile))
    exe("silent! !mv -f '".tagmaster#TmpFName(l:tagfile)."' ".l:tagfile."")
    return
  endif

  echohl vimError
  echo "Error: No tag files found!"
endfunction

function! tagmaster#RelFName(name, tagname)
  let downpath = ""
  let relpath = "/"

  while relpath[0] == "/"
    let tagpath = fnamemodify(a:tagname, ":p:h".downpath)."/"
    let relpath = substitute(fnamemodify(a:name, ":p"), tagpath, "", "")
    if relpath != fnamemodify(a:name, ":p")
      let relpath = substitute(downpath, ":h", "\.\./", "g") . relpath
    endif
    let downpath = downpath . ":h"
  endwhile
  return relpath
endfunction

function! tagmaster#TmpFName(name)
  let tmpnam = fnamemodify(a:name, ":p:h")."/.at.".fnamemodify(a:name, ":p:t")
  return tmpnam
endfunction

exe("source ".expand(expand("<sfile>:h"))."/ftypes.vim")
