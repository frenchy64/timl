" timl.vim - TimL
" Maintainer:   Tim Pope <code@tpope.net>

if exists("g:loaded_timl") || v:version < 700 || &cp
  finish
endif
let g:loaded_timl = 1

if &maxfuncdepth == 100
  set maxfuncdepth=200
endif

augroup timl
  autocmd!
  autocmd BufNewFile,BufReadPost *.tim set filetype=timl
  autocmd FileType timl command! -buffer -bar Wepl :update|source %|TLrepl
  autocmd SourceCmd *.tim call timl#source_file(expand("<amatch>"))
  autocmd FuncUndefined *#* call s:autoload(expand('<amatch>'))
augroup END

command! -bar -nargs=? TLrepl :call s:repl(<f-args>)
command! -bar -nargs=1 -complete=expression TLinspect :echo timl#pr_str(<args>)

if !exists('g:timl#requires')
  let g:timl#requires = {}
endif

function! s:autoload(function) abort
  let ns = matchstr(a:function, '.*\ze#')

  if !has_key(g:timl#requires, ns)
    let g:timl#requires[ns] = 1
    for file in findfile('autoload/'.tr(ns,'#','/').'.tim', &rtp, -1)
      call timl#source_file(file, ns)
      " drop to run all if include guards are added
      return
    endfor
  endif
endfunction

let s:repl_env = {'*e': g:timl#nil, '*1': g:timl#nil}

function! s:repl(...)
  let cmpl = 'customlist,timl#reflect#input_complete'
  let more = &more
  try
    set nomore
    let g:timl#core#_STAR_ns_STAR_ = timl#symbol(a:0 ? a:1 : timl#ns_for_file(expand('%:p')))
    let input = input(g:timl#core#_STAR_ns_STAR_[0].'=> ', '', cmpl)
    while !empty(input)
      echo "\n"
      try
        while 1
          try
            let read = timl#reader#read_string_all(input)
            break
          catch /^timl.vim: unexpected EOF/
            let space = repeat(' ', len(g:timl#core#_STAR_ns_STAR_[0])-2)
            let input .= "\n" . input(space.'#_=> ', '', cmpl)
            echo "\n"
          endtry
        endwhile
        let s:repl_env['*1'] = timl#eval([timl#symbol('do')] + read, [s:repl_env, g:timl#core#_STAR_ns_STAR_[0], 'timl#repl'])
        echo timl#pr_str(s:repl_env['*1'])
      catch /^timl#repl: EXIT/
        return ''
      catch
        let s:repl_env['*e'] = timl#build_exception(v:exception, v:throwpoint)
        echohl ErrorMSG
        echo v:exception
        echohl NONE
      endtry
      let input = input(g:timl#core#_STAR_ns_STAR_[0].'=> ', '', cmpl)
    endwhile
  finally
    let &more = more
  endtry
endfunction

" vim:set et sw=2:
