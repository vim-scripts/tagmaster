Tagmaster is a plugin aimed for easy operating with tags and tag files.
It allows to generate tags for current project or file, delete tags for given file,
update tags, etc.
Tags file name can be either specified explicitly, or deduced. Any tag file (found
with tagfiles() function) is checked for if it can belong to current project (placed
at the same directory level, or several levels up).
Before updating tags for given file, they all are deleted first to avoid duplicate
tags.
When generating tags for project, current filetype is considered and only files of
this filetype are scanned. This is done to avoid collecting garbage from auxiliary
files like config scripts, Makefiles, etc.

Added commands: 
  TGenerate/TGen - generate tags for current project
  TGen [-recurse] [-norecurse] [-append] [tagfilename]
    arguments: 
      -recurse      recurse into subdirectories
      -norecurse    don't recurse into subdirectories
      -append       append tags rather than generate new file (similar to -a ctags option)
      tagfilename   tag file name (uses default if not specified)

  TUpdate/TUp
  TUp [-add/-noadd] [filename] [tagfilename]
    arguments:
      -add          add tags for given file if they aren't already there.
      -noadd        don't add tags for given file if they aren't there (update only).
      filename      file for which to update tags. Current file if not specified.
      tagfilename   tags file name (deduced or default if not specified)
      
  TDelete/TDel
  TDel [filename] [tagfilename]
    arguments:
      filename      file for which to delete tags. Current file if not specified.
      tagfilename   tags file name (deduced or default if not specified)

Some configuration variables that affect behaviour:

  g:tagmaster_enable_autotags = 0
enable or disable automatic tags updating when file is saved

  g:tagmaster_options = "--fields=+iaS --extra=+q --c-kinds=+pd --c++-kinds=+pd"
additional options for ctags (though in my opinion the better way is to specify them in your ~/.ctags file)

  g:tagmaster_recursive = 1
whether or not generate tags recursively by default (when neither -recurse nor -norecurse is specified)

  g:tagmaster_addupdate = 1
whether or not allow adding tags on update by default (when neither -add nor -noadd specified)
