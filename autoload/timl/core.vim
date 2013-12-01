if exists("g:autoloaded_timl_core") || &cp || v:version < 700
  finish
endif
let g:autoloaded_timl_core = 1

let s:true = g:timl#true
let s:false = g:timl#false

" Section: Types {{{1

function! timl#core#type(val) abort
  let type = type(a:val)
  if type == type([])
    if timl#symbolp(a:val)
      return -1
    elseif timl#symbolp(get(a:val, 0)) && a:val[0][0][0] ==# '#'
      return a:val[0][0][1:-1]
    endif
  elseif type == type({})
    if timl#symbolp(get(a:val, '#type')) && a:val['#type'][0][0] ==# '#'
      return a:val['#type'][0][1:-1]
    endif
  endif
  return type
endfunction

function! timl#core#nil_QMARK_(val) abort
  return a:val is# g:timl#nil
endfunction

function! timl#core#symbol_QMARK_(obj) abort
  return timl#symbolp(a:obj)
endfunction

function! timl#core#string_QMARK_(obj) abort
  return type(a:obj) == type('')
endfunction

function! timl#core#integer_QMARK_(obj) abort
  return type(a:obj) == type(0)
endfunction

function! timl#core#float_QMARK_(obj) abort
  return type(a:obj) == 5
endfunction

function! timl#core#number_QMARK_(obj) abort
  return type(a:obj) == type(0) || type(a:obj) == 5
endfunction

function! timl#core#symbol(str) abort
  return timl#symbol(a:str)
endfunction

function! timl#core#string(...) abort
  let acc = ''
  let _ = {}
  for _.x in a:000
    if timl#symbolp(_.x)
      let acc .= substitute(_.x[0], '^:', '', '')
    elseif type(_.x) == type('')
      let acc .= _.x
    elseif type(_.x) == type(function('tr'))
      return substitute(join([_.x]), '[{}]', '', 'g')
    else
      let acc .= string(_.x)
    endif
  endfor
  return acc
endfunction

" }}}1
" Section: Functional {{{1

function! timl#core#identity(x) abort
  return a:x
endfunction

function! timl#core#apply(f, x, ...) abort
  let args = [a:x] + a:000
  if type(args[-1]) == type({})
    let dict = remove(args, -1)
  else
    let dict = 0
  endif
  if type(args[-1]) != type([])
    throw 'timl: last non-dict argument to apply must be a list'
  endif
  let args = args[0:-2] + args[-1]
  return timl#call(a:f, args, dict)
endfunction

function! timl#core#throw(val) abort
  throw a:val
endfunction

" }}}1
" Section: IO {{{1

function! timl#core#echo(...) abort
  echo call('timl#core#string', a:000, {})
  return g:timl#nil
endfunction

function! timl#core#echomsg(...) abort
  echomsg call('timl#core#string', a:000, {})
  return g:timl#nil
endfunction

" }}}1
" Section: Operators {{{

function! timl#core#_PLUS_(...) abort
  let acc = 0
  for elem in a:000
    let acc += elem
  endfor
  return acc
endfunction

function! timl#core#_STAR_(...) abort
  let acc = 1
  for elem in a:000
    let acc = acc * elem
  endfor
  return acc
endfunction

function! timl#core#_(x, ...) abort
  if a:0
    let acc = a:x
    for elem in a:000
      let acc -= elem
    endfor
    return acc
  else
    return -a:x
  endif
endfunction

function! timl#core#_SLASH_(x, ...) abort
  if a:0
    let acc = a:x
    for elem in a:000
      let acc = acc / elem
    endfor
    return acc
  else
    return 1 / a:x
  endif
endfunction

function! timl#core#rem(x, y) abort
  return a:x % a:y
endfunction

function! timl#core#_GT_(x, y) abort
  return a:x ># a:y ? s:true : s:false
endfunction

function! timl#core#_LT_(x, y) abort
  return a:x <# a:y ? s:true : s:false
endfunction

function! timl#core#_GT__EQ_(x, y) abort
  return a:x >=# a:y ? s:true : s:false
endfunction

function! timl#core#_LT__EQ_(x, y) abort
  return a:x <=# a:y ? s:true : s:false
endfunction

function! timl#core#_EQ__TILDE_(x, y) abort
  return type(a:x) == type('') && type(a:y) == type('') && a:x =~# a:y ? s:true : s:false
endfunction

function! timl#core#_EQ__TILDE__QMARK_(x, y) abort
  return type(a:x) == type('') && type(a:y) == type('') && a:x =~? a:y ? s:true : s:false
endfunction

function! s:ntype(x) abort
  let t = timl#core#type(a:x)
  return t == 5 ? 0 : t
endfunction

function! timl#core#_EQ_(x, y) abort
  return type(a:x) == type(a:y) && a:x ==# a:y ? s:true : s:false
endfunction

function! timl#core#equal_QMARK_(x, y) abort
  return s:ntype(a:x) == s:ntype(a:y) && a:x ==# a:y ? s:true : s:false
endfunction

function! timl#core#eq_QMARK_(x, y) abort
  return a:x is# a:y ? s:true : s:false
endfunction

" }}}1
" Section: Lists {{{1

function! timl#core#first(list) abort
  return get(a:list, 0, g:timl#nil)
endfunction

function! timl#core#rest(list) abort
  return a:list[1:-1]
endfunction

function! timl#core#car(list) abort
  return get(a:list, 0, g:timl#nil)
endfunction

function! timl#core#cdr(list) abort
  return a:list[1:-1]
endfunction

function! timl#core#list(...) abort
  return a:000
endfunction

function! timl#core#sublist(list, start, ...) abort
  if a:0
    return a:list[a:start : a:1]
  else
    return a:list[a:start :]
  endif
endfunction

function! timl#core#slice(list, start, ...) abort
  if a:0 && a:1 == 0
    return type(a:list) == type('') ? '' : []
  elseif a:0
    return a:list[a:start : (a:1 < 0 ? a:1 : a:1-1)]
  else
    return a:list[a:start :]
  endif
endfunction

function! timl#core#list_QMARK_(val) abort
  return !timl#symbolp(a:val) && type(a:val) == type([])
endfunction

function! timl#core#append(...) abort
  let acc = []
  for elem in a:000
    call extend(acc, elem)
  endfor
  return acc
endfunction

function! timl#core#cons(val, list) abort
  return [a:val] + a:list
endfunction

" }}}1
" Section: Dictionaries {{{1

function! timl#core#dict(...) abort
  let list = copy(a:000)
  while len(a:000) % 2 !=# 0 && timl#core#list_QMARK_(list[-1])
    call extend(list, remove(list, -1))
  endwhile
  if len(list) % 2 !=# 0
    throw 'timl: dict requires a even number of arguments'
  endif
  let dict = {}
  for i in range(0, len(list)-1, 2)
    let dict[timl#core#string(list[i])] = list[i+1]
  endfor
  return dict
endfunction

function! timl#core#dict_QMARK_(val) abort
  return type(a:val) == type({})
endfunction

function! timl#core#assoc(dict, ...) abort
  return extend(timl#core#dict(a:000), a:dict, 'keep')
endfunction

function! timl#core#dissoc(dict, ...) abort
  let dict = copy(a:dict)
  for key in a:000
    if has_key(dict, key)
      call remove(dict, key)
    endif
  endfor
  return dict
endfunction

" }}}1
" Section: Collections {{{1

function! timl#core#seq(coll)
  let t = timl#core#type(a:coll)
  if t == type({})
    let seq = items(a:coll)
    lockvar seq
  elseif t == type([])
    let seq = timl#persistent(a:coll)
  endif
  if exists('seq')
    return empty(seq) ? g:timl#nil : seq
  endif
  throw 'timl: not seqable'
endfunction

function! timl#core#length(coll) abort
  let t = timl#core#type(a:coll)
  if type(t) == type('')
    return len(a:coll) - 1
  endif
  return len(a:coll)
endfunction

function! timl#core#empty_QMARK_(coll)
  return timl#core#length(a:coll) ? s:false : s:true
endfunction

function! timl#core#empty(coll) abort
  if type(a:coll) == type({})
    return {}
  elseif type(a:coll) == type('')
    return ''
  elseif type(a:coll) == type([]) && !timl#symbolp(a:coll)
    return []
  endif
  return g:timl#nil
endfunction

function! timl#core#get(coll, key, ...) abort
  let def = a:0 ? a:1 : g:timl#nil
  let t = timl#core#type(a:coll)
  if type(a:coll) == type([])
    if type(a:key) != type(0)
      return a:0 ? a:1 : g:timl#nil
    endif
    return get(a:coll, a:key + (a:key > 0 && type(t) ==# type('')), def)
  endif
  return get(a:coll, timl#core#string(a:key), a:0 ? a:1 : def)
endfunction

function! timl#core#map(f, coll) abort
  let seq = timl#core#seq(a:coll)
  if empty(seq)
    return seq
  endif
  let result = map(timl#transient(seq), 'timl#call(a:f, [v:val])')
  lockvar result
  return result
endfunction

function! timl#core#reduce(f, coll, ...) abort
  let _ = {}
  if a:0
    let _.val = a:coll
    let coll = timl#core#seq(a:1)
  else
    let coll = timl#transient(timl#core#seq(a:coll))
    if empty(coll)
      return g:timl#nil
    endif
    let _.val = remove(coll, 0)
  endif
  for _.elem in coll
    let _.val = timl#call(a:f, [_.val, _.elem])
  endfor
  return _.val
endfunction

" }}}1
" Section: Namespaces {{{1

function! timl#core#in_ns(ns)
  call timl#create_ns(timl#core#string(a:ns))
  let g:timl#core#_STAR_ns_STAR_ = timl#symbol(a:ns)
  return g:timl#core#_STAR_ns_STAR_
endfunction

function! timl#core#refer(ns)
  let me = timl#core#string(g:timl#core#_STAR_ns_STAR_)
  call timl#create_ns(me, {'referring': [a:ns]})
  return g:timl#nil
endfunction

function! timl#core#alias(alias, ns)
  let me = timl#core#string(g:timl#core#_STAR_ns_STAR_)
  call timl#create_ns(me, {'aliases': {timl#core#string(a:alias): a:ns}})
  return g:timl#nil
endfunction

" }}}1

call timl#source_file(expand('<sfile>:r') . '.macros.tim', 'timl#core')
call timl#source_file(expand('<sfile>:r') . '.basics.tim', 'timl#core')
call timl#source_file(expand('<sfile>:r') . '.coll.tim', 'timl#core')
call timl#source_file(expand('<sfile>:r') . '.vim.tim', 'timl#core')

" vim:set et sw=2:
