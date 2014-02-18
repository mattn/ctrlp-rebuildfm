if exists('g:loaded_ctrlp_rebuildfm') && g:loaded_ctrlp_rebuildfm
  "finish
endif
let g:loaded_ctrlp_rebuildfm = 1
let s:system = function(get(g:, 'webapi#system_function', 'system'))

let s:rebuildfm_var = {
\  'init':   'ctrlp#rebuildfm#init()',
\  'exit':   'ctrlp#rebuildfm#exit()',
\  'accept': 'ctrlp#rebuildfm#accept',
\  'lname':  'rebuildfm',
\  'sname':  'rebuildfm',
\  'type':   'path',
\  'sort':   0,
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:rebuildfm_var)
else
  let g:ctrlp_ext_vars = [s:rebuildfm_var]
endif

function! s:attr(node, name)
  let n = a:node.childNode(a:name)
  if empty(n)
    return ""
  endif
  return n.value()
endfunction

function! s:enclosure(node, name)
  let n = a:node.childNodes(a:name)
  if empty(n)
    return []
  endif
  return map(n, 'v:val.attr["url"]')
endfunction

function! s:parseFeed(url)
  let dom = webapi#xml#parseURL(a:url)
  let items = []
  let channel = dom.childNode('channel')
  for item in channel.childNodes('item')
    call add(items, {
    \  "title": s:attr(item, 'title'),
    \  "link": s:attr(item, 'link'),
    \  "content": s:attr(item, 'description'),
    \  "id": s:attr(item, 'guid'),
    \  "date": s:attr(item, 'pubDate'),
    \  "enclosure": s:enclosure(item, 'enclosure'),
    \})
  endfor
	return items
endfunction

function! s:format_rebuildfm(item)
  return printf("%s\t\t\t%s", a:item.title, a:item.link)
endfunction

function! ctrlp#rebuildfm#init()
  let s:list = s:parseFeed('http://feeds.rebuild.fm/rebuildfm')
  return map(copy(s:list), 's:format_rebuildfm(v:val)')
endfunc

function! ctrlp#rebuildfm#accept(mode, str)
  let found = {}
  for item in s:list
    if stridx(a:str, item.title) == 0
      let found = copy(item)
      break
    endif
	endfor
  call ctrlp#exit()
  redraw!
  if !empty(found)
    let dom = webapi#html#parse('<div>' . item.content . '</div>')
    echohl Title | echo item.title | echohl None
    echo dom.value()
    if has("gui_running")
      silent exec "!mplayer -really-quiet -msglevel global=4 " . shellescape(found.enclosure[0])
    else
      call system("mplayer -really-quiet -msglevel global=4 " . shellescape(found.enclosure[0]))
    endif
  endif
endfunction

function! ctrlp#rebuildfm#exit()
  if exists('s:list')
    unlet! s:list
  endif
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#rebuildfm#id()
  return s:id
endfunction

" vim:fen:fdl=0:ts=2:sw=2:sts=2
