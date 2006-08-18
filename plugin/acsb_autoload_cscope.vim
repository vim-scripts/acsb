" Vim global plugin for autoloading cscope databases.
" Last Change: Mon Jan 28 11:59:05 CST 2002
" Maintainer: Michael Conrad Tilsra <tadpol@tadpol.org>
" Revision: 0.3
" Modified: Gabor Fekete for acsb.vim

if exists("acsb_loaded_autoload_cscope")
	finish
endif
let loaded_acsb_autoload_cscope = 1

let s:cscope_prefix_0 = ""
let s:cscope_prefix_1 = "cscope-data/"
let s:cscope_prefix_2 = "kscope-data/"
let s:cscope_prefix_3 = "codelight-data/"
let s:cscope_prefix_count = 4

" requirements, you must have these enables or this is useless.
if(  !has('cscope') || !has('modify_fname') )
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" If you set this to anything other than 1, the menu and macros will not be
" loaded.  Useful if you have your own that you like.  Or don't want my stuff
" clashing with any macros you've made.
if !exists("g:autocscope_menus")
  let g:autocscope_menus = 1
endif

"==
" windowdir
"  Gets the directory for the file in the current window
"  Or the current working dir if there isn't one for the window.
function s:windowdir()
  if winbufnr(0) == -1
    return getcwd()
  endif
  return fnamemodify(bufname(winbufnr(0)), ':p:h')
endfunc
"
"==
" Find_in_parent
" find the file argument and returns the path to it.
" Starting with the current working dir, it walks up the parent folders
" until it finds the file, or it hits the stop dir.
" If it doesn't find it, it returns "Nothing"
function s:Find_in_parent(fln,flsrt,flstp)
  let here = a:flsrt
  while ( strlen( here) > 0 )
    if filereadable( here . "/" . a:fln )
      return here
    endif
    let fr = match(here, "/[^/]*$")
    if fr == -1
      break
    endif
    let here = strpart(here, 0, fr)
    if here == a:flstp
      break
    endif
  endwhile
  return "Nothing"
endfunc
"
"==
" Cycle_macros_menus
"  if there are cscope connections, activate that stuff.
"  Else toss it out.
"  TODO Maybe I should move this into a seperate plugin?
let s:menus_loaded = 0
function s:Cycle_macros_menus()
  if g:autocscope_menus != 1
    return
  endif
  if cscope_connection()
    if s:menus_loaded == 1
      return
    endif
    let s:menus_loaded = 1
    set csto=0
    set cst
    silent! map <unique> <C-\>s :cs find c <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>f :cs find f <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>i :cs find i <C-R>=expand("<cword>")<CR><CR>
    if has("menu")
      nmenu &Cscope.Find.Symbol<Tab><c-\>s
        \ :cs find s <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Definition<Tab><c-\>g
        \ :cs find g <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Called<Tab><c-\>d
        \ :cs find d <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Calling<Tab><c-\>c
        \ :cs find c <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Assignment<Tab><c-\>t
        \ :cs find t <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Egrep<Tab><c-\>e
        \ :cs find e <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.File<Tab><c-\>f
        \ :cs find f <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Including<Tab><c-\>i
        \ :cs find i <C-R>=expand("<cword>")<CR><CR>
"      nmenu &Cscope.Add :cs add 
"      nmenu &Cscope.Remove  :cs kill 
      nmenu &Cscope.Reset :cs reset<cr>
      nmenu &Cscope.Show :cs show<cr>
      " Need to figure out how to do the add/remove. May end up writing
      " some container functions.  Or tossing them out, since this is supposed
      " to all be automatic.
    endif
  else
    let s:menus_loaded = 0
    set nocst
    silent! unmap <C-\>s
    silent! unmap <C-\>g
    silent! unmap <C-\>d
    silent! unmap <C-\>c
    silent! unmap <C-\>t
    silent! unmap <C-\>e
    silent! unmap <C-\>f
    silent! unmap <C-\>i
    if has("menu")  " would rather see if the menu exists, then remove...
      silent! nunmenu Cscope
    endif
  endif
endfunc
"
"==
" Unload_csdb
"  drop cscope connections.
function s:Unload_csdb()
  if exists("b:csdbpath")
    if cscope_connection(3, "out", b:csdbpath)
      let save_csvb = &csverb
      set nocsverb
      exe "cs kill " . b:csdbpath
      set csverb
      let &csverb = save_csvb
    endif
  endif
endfunc
"
"==
" Cycle_csdb
"  cycle the loaded csccope db.
function s:Cycle_csdb()
    if exists("b:csdbpath")
      if cscope_connection(3, "out", b:csdbpath)
        return
        "it is already loaded. don't try to reload it.
      endif
    endif

    " Look up cscope.out
    let i = 0
    let newcsdbpath = "Nothing"
    while i < s:cscope_prefix_count
      let newcsdbpath = s:Find_in_parent(s:cscope_prefix_{i} . "cscope.out", s:windowdir(), $HOME)
      if newcsdbpath != "Nothing"
        let newcsdbpath = newcsdbpath . "/" . s:cscope_prefix_{i}
        break
      endif
      let i = i + 1
    endwhile
    if newcsdbpath != "Nothing"
      let b:csdbpath = newcsdbpath
      if !cscope_connection(3, "out", b:csdbpath)
        let save_csvb = &csverb
        set nocsverb
        exe "cs add " . b:csdbpath . "/cscope.out " . b:csdbpath
        set csverb
        let &csverb = save_csvb
      endif
      "
      call ACSB_setupdb()
    else " No cscope database, undo things. (someone rm-ed it or somesuch)
      call s:Unload_csdb()
"      echo "Fuck! No cscope.out was found!"
    endif
endfunc

" auto toggle the menu
augroup acsb_autoload_cscope
 au!
 au BufEnter *.[chly]  call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.cc      call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.[chly] call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.cc     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
augroup END

let &cpo = s:save_cpo

