" Maintainer:   Tim Pope <http://tpo.pe/>

if exists("g:autoloaded_timl")
  finish
endif
let g:autoloaded_timl = 1

" Section: Util {{{1

function! s:funcname(name) abort
  return substitute(a:name,'^s:',matchstr(expand('<sfile>'), '.*\zs<SNR>\d\+_'),'')
endfunction

function! s:function(name) abort
  return function(s:funcname(a:name))
endfunction

" }}}1
" Section: Data types {{{1

let s:types = {
      \ 0: 'timl#vim#Number',
      \ 1: 'timl#vim#String',
      \ 2: 'timl#vim#Funcref',
      \ 3: 'timl#vim#List',
      \ 4: 'timl#vim#Dictionary',
      \ 5: 'timl#vim#Float'}


function! timl#truth(val) abort
  return !(empty(a:val) || a:val is 0)
endfunction

function! timl#type(val) abort
  let type = get(s:types, type(a:val), 'timl#vim#unknown')
  if type == 'timl#vim#List'
    if timl#symbolp(a:val)
      return 'timl#lang#Symbol'
    elseif a:val is# g:timl#nil
      return 'timl#lang#Nil'
    elseif timl#symbolp(get(a:val, 0)) && a:val[0][0][0] ==# '#'
      return a:val[0][0][1:-1]
    endif
  elseif type == 'timl#vim#Dictionary'
    if timl#symbolp(get(a:val, '#tag')) && a:val['#tag'][0][0] ==# '#'
      return a:val['#tag'][0][1:-1]
    endif
  endif
  return type
endfunction

function! timl#implementsp(fn, obj)
  return exists('*'.tr(timl#type(a:obj) . '#' . a:fn, '-', '_'))
endfunction

runtime! autoload/timl/lang.vim
runtime! autoload/timl/vim.vim
function! timl#dispatch(proto, fn, obj, ...)
  let t = timl#type(a:obj)
  let obj = tr(t, '-', '_')
  if type(get(g:, obj)) == type({})
    let impls = get(g:{t}, "implements", {})
    let proto = timl#str(a:proto)
    if has_key(impls, proto)
      return timl#call(impls[proto][timl#str(a:fn)], [a:obj] + a:000)
    endif
  else
    throw "timl: type " . t . " undefined"
  endif
  throw "timl:E117: ".t." doesn't implement ".a:proto
endfunction

function! timl#lock(val) abort
  let val = a:val
  lockvar val
  return val
endfunction

function! timl#persistentp(val) abort
  let val = a:val
  return islocked('val')
endfunction

function! timl#persistent(val) abort
  let val = a:val
  if islocked('val')
    return val
  else
    let val = copy(a:val)
    lockvar val
    return val
  endif
endfunction

function! timl#transient(val) abort
  let val = a:val
  if islocked('val')
    return copy(val)
  else
    return val
  endif
endfunction

function! s:freeze(...) abort
  return a:000
endfunction

if !exists('g:timl#nil')
  let g:timl#nil = s:freeze()
  let g:timl#false = g:timl#nil
  let g:timl#true = 1
  lockvar g:timl#nil g:timl#false g:timl#true
endif

function! timl#str(val) abort
  return s:string(a:val)
endfunction

function! s:string(val) abort
  if type(a:val) == type('')
    return a:val
  elseif type(a:val) == type(function('tr'))
    return substitute(join([a:val]), '[{}]', '', 'g')
  elseif timl#symbolp(a:val)
    return substitute(a:val[0], '^:', '', '')
  elseif timl#consp(a:val)
    let _ = {'val': a:val}
    let acc = ''
    while timl#consp(_.val)
      let acc .= s:string(timl#car(_.val)) . ','
      let _.val = timl#cdr(_.val)
    endwhile
    return acc
  elseif type(a:val) == type([])
    return join(map(copy(a:val), 's:string(v:val)'), ',').','
  else
    return string(a:val)
  endif
endfunction

function! timl#key(key)
  if type(a:key) == type(0)
    return string(a:key)
  elseif timl#symbolp(a:key) && a:key[0][0] =~# '[:#]'
    return a:key[0][1:-1]
  else
    return ' '.timl#printer#string(a:key)
  endif
endfunction

function! timl#dekey(key)
  if a:key =~# '^#'
    throw 'timl: invalid key '.a:key
  elseif a:key =~# '^ '
    return timl#reader#read_string(a:key[1:-1])
  elseif a:key =~# '^[-+]\=\d'
    return timl#reader#read_string(a:key)
  else
    return timl#symbol(':'.a:key)
  endif
endfunction

" }}}1
" Section: Symbols {{{1

if !exists('g:timl#symbols')
  let g:timl#symbols = {}
endif

function! timl#symbol(str)
  let str = type(a:str) == type([]) ? a:str[0] : a:str
  if !has_key(g:timl#symbols, str)
    let g:timl#symbols[str] = s:freeze(str)
  endif
  return g:timl#symbols[str]
endfunction

function! timl#symbolp(symbol)
  return type(a:symbol) == type([]) &&
        \ len(a:symbol) == 1 &&
        \ type(a:symbol[0]) == type('') &&
        \ get(g:timl#symbols, a:symbol[0], 0) is a:symbol
endfunction

" From clojure/lange/Compiler.java
let s:munge = {
      \ ',': "_COMMA_",
      \ ':': "_COLON_",
      \ '+': "_PLUS_",
      \ '>': "_GT_",
      \ '<': "_LT_",
      \ '=': "_EQ_",
      \ '~': "_TILDE_",
      \ '!': "_BANG_",
      \ '@': "_CIRCA_",
      \ '#': "_SHARP_",
      \ "'": "_SINGLEQUOTE_",
      \ '"': "_DOUBLEQUOTE_",
      \ '%': "_PERCENT_",
      \ '^': "_CARET_",
      \ '&': "_AMPERSAND_",
      \ '*': "_STAR_",
      \ '|': "_BAR_",
      \ '{': "_LBRACE_",
      \ '}': "_RBRACE_",
      \ '[': "_LBRACK_",
      \ ']': "_RBRACK_",
      \ '/': "_SLASH_",
      \ '\\': "_BSLASH_",
      \ '?': "_QMARK_"}

let s:demunge = {}
for s:key in keys(s:munge)
  let s:demunge[s:munge[s:key]] = s:key
endfor
unlet! s:key

function! timl#munge(var) abort
  let var = s:string(a:var)
  return tr(substitute(var, '[^[:alnum:]:#_-]', '\=get(s:munge,submatch(0), submatch(0))', 'g'), '-', '_')
endfunction

function! timl#demunge(var) abort
  let var = s:string(a:var)
  return tr(substitute(var, '_\(\u\+\)_', '\=get(s:demunge, submatch(0), submatch(0))', 'g'), '_', '-')
endfunction

function! timl#a2env(f, a) abort
  let env = {}
  if get(a:f.arglist, -1) is timl#symbol('...')
    let env['...'] = a:a['000']
  endif
  let _ = {}
  for [k,_.V] in items(a:a)
    if k !~# '^\d' && k !=# 'firstline' && k !=# 'lastline'
      let k = timl#demunge(k)
      if k =~# ',$'
        let keys = split(k, ',')
        for i in range(len(keys))
          if type(_.V) == type([])
            let env[keys[i]] = get(_.V, i, g:timl#nil)
          elseif type(_.V) == type({})
            let env[keys[i]] = get(_.V, keys[i], g:timl#nil)
          endif
        endfor
      else
        let env[k] = _.V
      endif
    endif
  endfor
  return env
endfunction

function! timl#l2env(f, args) abort
  let args = a:args
  let env = {}
  let _ = {}
  let i = 0
  for _.param in timl#vec(a:f.arglist)
    if i >= len(args)
      throw 'timl: arity error'
    endif
    if timl#symbolp(_.param)
      let env[_.param[0]] = args[i]
    elseif type(_.param) == type([])
      for j in range(len(_.param))
        let key = s:string(_.param[j])
        if type(args[i]) == type([])
          let env[key] = get(args[i], j, g:timl#nil)
        elseif type(args[i]) == type({})
          let env[key] = get(args[i], key, g:timl#nil)
        endif
      endfor
    else
      throw 'timl: unsupported param '.string(param)
    endif
    let i += 1
  endfor
  return env
endfunction

" }}}1
" Section: Lists {{{1

let s:cons = timl#symbol('#timl#lang#Cons')

function! timl#vectorp(obj) abort
  return type(a:obj) == type([]) && a:obj isnot# g:timl#nil && !timl#symbolp(a:obj)
endfunction

function! timl#consp(obj) abort
  return type(a:obj) == type({}) && get(a:obj, '#tag') is# s:cons
endfunction

function! timl#list(...) abort
  return timl#list2(a:000)
endfunction

function! timl#cons(car, cdr) abort
  let cons = {'#tag': s:cons, 'car': a:car, 'cdr': a:cdr}
  lockvar cons
  return cons
endfunction

function! timl#car(cons) abort
  if timl#consp(a:cons)
    return a:cons.car
  endif
  throw 'timl: not a cons cell'
endfunction

function! timl#cdr(cons) abort
  if timl#consp(a:cons)
    return a:cons.cdr
  endif
  throw 'timl: not a cons cell'
endfunction

function! timl#list2(array)
  let _ = {'cdr': g:timl#nil}
  for i in range(len(a:array)-1, 0, -1)
    let _.cdr = timl#cons(a:array[i], _.cdr)
  endfor
  return _.cdr
endfunction

function! timl#vec(cons)
  if !timl#consp(a:cons)
    return copy(a:cons)
  endif
  let array = []
  let _ = {'cons': a:cons}
  while timl#consp(_.cons)
    call add(array, timl#car(_.cons))
    let _.cons = timl#cdr(_.cons)
  endwhile
  return timl#persistent(extend(array, _.cons))
endfunction

function! timl#count(cons) abort
  let i = 0
  let _ = {'cons': a:cons}
  while timl#consp(_.cons)
    let i += 1
    let _.cons = timl#cdr(_.cons)
  endwhile
  return i + len(_.cons)
endfunction

" }}}1
" Section: Garbage collection {{{1

if !exists('g:timl#lambdas')
  let g:timl#lambdas = {}
endif

function! timl#gc()
  let l:count = 0
  for fn in keys(g:timl#lambdas)
    try
      if fn =~# '^\d'
        let Fn = function('{'.fn.'}')
      else
        let Fn = function(fn)
      endif
    catch /^Vim\%((\a\+)\)\=:E700/
      call remove(g:timl#lambdas, fn)
      let l:count += 1
    endtry
  endfor
  return l:count
endfunction

augroup timl#gc
  autocmd!
  autocmd CursorHold * call timl#gc()
augroup END

" }}}1
" Section: Namespaces {{{1

let s:ns = timl#symbol('#namespace')

function! timl#create_ns(name, ...)
  let name = s:string(a:name)
  if !has_key(g:timl#namespaces, a:name)
    let g:timl#namespaces[a:name] = {'#tag': s:ns, 'referring': ['timl#core'], 'aliases': {}}
  endif
  let ns = g:timl#namespaces[a:name]
  if !a:0
    return ns
  endif
  let opts = a:1
  let _ = {}
  for _.refer in get(opts, 'referring', [])
    let str = s:string(_.refer)
    if name !=# str && index(ns.referring, str) < 0
      call insert(ns.referring, str)
    endif
  endfor
  for [_.name, _.target] in items(get(opts, 'aliases', {}))
    let ns.aliases[_.name] = s:string(_.target)
  endfor
  return ns
endfunction

if !exists('g:timl#namespaces')
  let g:timl#namespaces = {
        \ 'timl#core': {'#tag': s:ns, 'referring': [], 'aliases': {}},
        \ 'user':      {'#tag': s:ns, 'referring': ['timl#core'], 'aliases': {}}}
endif

" }}}1
" Section: Eval {{{1

function! timl#call(Func, args, ...) abort
  let dict = (a:0 && type(a:1) == type({})) ? a:1 : {'__fn__': a:Func}
  if timl#symbolp(a:Func)
    return call('timl#core#get', a:args[0:0] + [a:Func] + a:args[1:-1])
  else
    return call(a:Func, a:args, dict)
  endif
endfunction

function! s:lencompare(a, b)
  return len(a:b) - len(a:b)
endfunction

function! timl#ns_for_file(file) abort
  let file = fnamemodify(a:file, ':p')
  let candidates = []
  for glob in split(&runtimepath, ',')
    let candidates += filter(split(glob(glob), "\n"), 'file[0 : len(v:val)-1] ==# v:val && file[len(v:val)] =~# "[\\/]"')
  endfor
  if empty(candidates)
    return 'user'
  endif
  let dir = sort(candidates, s:function('s:lencompare'))[-1]
  let path = file[len(dir)+1 : -1]
  return substitute(tr(fnamemodify(path, ':r:r'), '\/_', '##-'), '^\%(autoload\|plugin\|test\)#', '', '')
endfunction

function! timl#lookup(sym, ns, locals) abort
  let sym = a:sym[0]
  if sym =~# '^[#:].'
    return a:sym
  elseif sym =~# '^f:' && exists('*'.sym[2:-1])
    return function(sym[2:-1])
  elseif sym =~# '^&.\|^\w:' && exists(sym)
    return eval(sym)
  elseif sym =~# '^@.$'
    return eval(sym)
  elseif sym =~# '.#'
    call timl#autoload(sym)
    let sym = timl#munge(sym)
    if exists('g:'.sym)
      return g:{sym}
    elseif exists('*'.sym)
      return function(sym)
    else
      throw 'timl: ' . sym . ' undefined'
    endif
  elseif has_key(a:locals, sym)
    return a:locals[sym]
  endif
  let ns = timl#find(sym, a:ns)
  if ns isnot# g:timl#nil
    let target = timl#munge(ns.'#'.sym)
    if exists('*'.target)
      return function(target)
    else
      return g:{target}
    endif
  endif
  throw 'timl: ' . sym . ' undefined'
endfunction

function! timl#find(sym, ns) abort
  let sym = type(a:sym) == type([]) ? a:sym[0] : a:sym
  let env = a:ns
  call timl#require(env)
  let ns = timl#create_ns(env)
  if sym =~# './.'
    let alias = matchstr(sym, '.*\ze/')
    let var = matchstr(sym, '.*/\zs.*')
    if has_key(ns.aliases, alias)
      return timl#find([ns.aliases[alias]], var)
    endif
  endif
  let target = timl#munge(env.'#'.sym)
  if exists('*'.target) || exists('g:'.target)
    return env
  endif
  for refer in ns.referring
    let target = timl#munge(s:string(refer).'#'.sym)
    call timl#require(refer)
    if exists('*'.target) || exists('g:'.target)
      return s:string(refer)
    endif
  endfor
  return g:timl#nil
endfunction

function! timl#qualify(envs, sym)
  let sym = type(a:sym) == type([]) ? a:sym[0] : a:sym
  if has_key(a:envs[0], sym)
    return a:sym
  endif
  let ns = timl#find(a:sym, a:envs[1])
  if type(ns) == type('')
    return timl#symbol(ns . '#' . sym)
  endif
  return a:sym
endfunction

function! s:build_function(name, arglist) abort
  let arglist = map(copy(timl#vec(a:arglist)), 'v:val is timl#symbol("...") ? "..." : timl#munge(v:val)')
  let dict = {}
  return 'function! '.a:name.'('.join(arglist, ',').") abort\n"
        \ . "let name = matchstr(expand('<sfile>'), '.*\\%(\\.\\.\\| \\)\\zs.*')\n"
        \ . "let fn = g:timl#lambdas[name]\n"
        \ . "let env = extend(timl#a2env(fn, a:), copy(fn.env), 'keep')\n"
        \ . "let nameenv = {}\n"
        \ . "if !empty(get(fn, 'name', ''))\n"
        \ . "let nameenv = {fn.name[0]: name =~ '^\\d' ? self.__fn__ : function(name)}\n"
        \ . "endif\n"
        \ . "call extend(env, nameenv, 'keep')\n"
        \ . "let _ = {}\n"
        \ . "let _.result = timl#eval(fn.form, fn.ns, env)\n"
        \ . "while type(_.result) == type([]) && get(_.result, 0) is# g:timl#recur_token\n"
        \ . "let env = extend(timl#l2env(fn, _.result[1:-1]), copy(fn.env), 'keep')\n"
        \ . "call extend(env, nameenv, 'keep')\n"
        \ . "let _.result = timl#eval(fn.form, fn.ns, env)\n"
        \ . "endwhile\n"
        \ . "return _.result\n"
        \ . "endfunction"
endfunction

function! s:lambda(name, arglist, form, ns, env) abort
  let dict = {}
  execute s:build_function('dict.function', a:arglist)
  let fn = matchstr(string(dict.function), "'\\zs.*\\ze'")
  let g:timl#lambdas[fn] = {
        \ 'ns': a:ns,
        \ 'arglist': a:arglist,
        \ 'env': a:env,
        \ 'form': a:form,
        \ 'macro': 0}
  if !empty(a:name)
    let g:timl#lambdas[fn].name = a:name
  endif
  return dict.function
endfunction

function! s:file4ns(ns) abort
  if !exists('s:tempdir')
    let s:tempdir = tempname()
  endif
  let file = s:tempdir . '/' . tr(timl#munge(a:ns), '#', '/') . '.vim'
  if !isdirectory(fnamemodify(file, ':h'))
    call mkdir(fnamemodify(file, ':h'), 'p')
  endif
  return file
endfunction

function! timl#build_exception(exception, throwpoint)
  let dict = {"exception": a:exception}
  let dict.line = +matchstr(a:throwpoint, '\d\+$')
  if a:throwpoint !~# '^function '
    let dict.file = matchstr(a:throwpoint, '^.\{-\}\ze\.\.')
  endif
  let dict.functions = map(split(matchstr(a:throwpoint, '\%( \|\.\.\)\zs.*\ze,'), '\.\.'), 'timl#demunge(v:val)')
  return dict
endfunction

if !exists('g:timl#core#_STAR_ns_STAR_')
  let g:timl#core#_STAR_ns_STAR_ = timl#symbol('user')
endif

function! timl#eval(x, ...) abort
  return call('timl#compiler#eval', [a:x] + a:000)

  if a:0
    let g:timl#core#_STAR_ns_STAR_ = timl#symbol(a:1)
  endif
  let envs = [{}, g:timl#core#_STAR_ns_STAR_[0]]

  return s:eval(a:x, envs)
endfunction

function! timl#define_global(global, val) abort
  if type(a:val) == type(function('tr'))
    let orig_name = s:string(a:val)
    let file = s:file4ns(matchstr(a:global, '.*\ze#'))
    if has_key(g:timl#lambdas, orig_name)
      redir => source
      silent! function {orig_name}
      redir END
      let body = split(source, "\n")
      if body[1] !~# '^\d'
        call remove(body, 1)
      endif
      call map(body, 'matchstr(v:val, "^\\d*\\s*\\zs.*")')
      if body[0] !~# '^function'
        let body = []
      endif
      let body[0] = substitute(body[0], ' \zs\w\+', a:global, '') . ' abort'
      let g:timl#lambdas[a:global] = g:timl#lambdas[orig_name]

    elseif orig_name =~# '^\d'
      throw 'timl: cannot define anonymous non-TimL function'

    else
      let body = [
            \ "function! ".a:global."(...) abort",
            \ "return call(".string(orig_name).", a:000)",
            \ "endfunction"]
    endif
    call writefile(body, file)
    let cmd = 'source '.file
  else
    let cmd = 'let g:'.a:global.' = a:val'
  endif
  if exists('*'.a:global) && a:global !~# '^[a-z][^#]*$'
    execute 'delfunction '.a:global
  endif
  unlet! g:{a:global}
  execute cmd
  if type(a:val) == type(function('tr'))
    return function(a:global)
  else
    return a:val
  endif
endfunction

function! timl#re(str, ...) abort
  return call('timl#eval', [timl#reader#read_string(a:str)] + a:000)
endfunction

function! timl#rep(...) abort
  return timl#printer#string(call('timl#re', a:000))
endfunction

function! timl#source_file(filename, ...)
  let old_ns = g:timl#core#_STAR_ns_STAR_
  try
    let ns = a:0 ? a:1 : timl#ns_for_file(fnamemodify(a:filename, ':p'))
    let g:timl#core#_STAR_ns_STAR_ = timl#symbol(ns)
    for expr in timl#reader#read_file(a:filename)
      call timl#eval(expr, ns)
    endfor
  catch /^Vim\%((\a\+)\)\=:E168/
  finally
    let g:timl#core#_STAR_ns_STAR_ = old_ns
  endtry
endfunction

if !exists('g:timl#requires')
  let g:timl#requires = {}
endif

function! timl#autoload(function) abort
  let ns = matchstr(a:function, '.*\ze#')
  call timl#require(ns)
endfunction

function! timl#require(ns) abort
  let ns = a:ns
  if !has_key(g:timl#requires, ns)
    let g:timl#requires[ns] = 1
    call timl#load(ns)
  endif
endfunction

function! timl#load(ns) abort
  let base = tr(a:ns,'#-','/_')
  execute 'runtime! autoload/'.base.'.vim'
  for file in findfile('autoload/'.base.'.tim', &rtp, -1)
    call timl#source_file(file, tr(a:ns, '_', '-'))
  endfor
endfunction

" }}}1
" Section: Tests {{{1

if !$TIML_TEST
  finish
endif

command! -nargs=1 TimLAssert
      \ try |
      \   if !eval(<q-args>) |
      \     echomsg "Failed: ".<q-args> |
      \   endif |
      \ catch /.*/ |
      \  echomsg "Error:  ".<q-args>." (".v:exception.")" . v:throwpoint |
      \ endtry

TimLAssert timl#re('(+ 1 2 3)') == 6

TimLAssert timl#re('(let [] (define forty-two 42))')
TimLAssert timl#re('forty-two') ==# 42

TimLAssert timl#re('(if 1 forty-two 69)') ==# 42
TimLAssert timl#re('(if 0 "boo" "yay")') ==# "yay"
TimLAssert timl#re('(begin 1 2)') ==# 2

TimLAssert empty(timl#re('(set! g:timl_setq (dict))'))
TimLAssert g:timl_setq ==# {}
let g:timl_setq = {}
TimLAssert empty(timl#re('(set! (. g:timl_setq key) ["a" "b"])'))
TimLAssert g:timl_setq ==# {"key": ["a", "b"]}
unlet! g:timl_setq

TimLAssert timl#re('(reduce (lambda (m (k v)) (append m (list v k))) ''() (dict "a" 1))') == [1, "a"]

TimLAssert timl#re('(dict "a" 1 "b" 2)') ==# {"a": 1, "b": 2}
TimLAssert timl#re('(dict "a" 1 ["b" 2])') ==# {"a": 1, "b": 2}
TimLAssert timl#re('(length "abc")') ==# 3

TimLAssert timl#re('(reduce + 0 (list 1 2 3))') ==# 6

TimLAssert timl#re("(loop [n 5 f 1] (if (<= n 1) f (recur (1- n) (* f n))))") ==# 120

delcommand TimLAssert

" }}}1

" vim:set et sw=2:
