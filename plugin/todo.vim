" populate the location list with the TODO comments from the current buffer
"TODO: put this plugin into its own repository and publish it
let g:todo_prefix = ['#', '//', '/*', '"', '!'] " list of line comment start markers
                                                "TODO: make these language-specific

"FIXME: hierarchical keyword spec so one keyword can belong to multiple groups
" groups: {
"   now: ['fixme', 'todo', 'fix', ],
"   fixme: ['fixme', 'fix', ],
" }
" keywords: {
"   fixme: 'FIXME',
"   todo: 'TODO',
"   fix: 'FIX',
" }
" indicates an ordinary note to the reader, usually not worth checking
let g:todo_note_keyword = [
\ 'DEPRECATED',
\ 'DEBUG',
\ 'NOTE',
\ 'TEST',
\ 'NB',
\]
let g:todo_note = 0
" indicates a crucial note to the reader (i.e. ignoring the note may cause you to make a mistake).
" usually only worth checking within the file you're working on
let g:todo_warning_keyword = [
\ 'ATTENTION',
\ 'ATTN',
\ 'BUG',
\ 'HEY',
\ 'XXX',
\]
let g:todo_warning = 1
" indicates a work item that should be looked at eventually
" (e.g. something minor is wrong that will take a lot of work to fix)
let g:todo_later_keyword = [
\ 'OPTIMIZE',
\ 'REFACTOR',
\ 'COMBAK',
\ 'REVIEW',
\ 'HACK',
\ 'TEMP',
\ 'TEST',
\ 'BUG',
\ 'TBD',
\ 'WTF',
\]
let g:todo_later = 0
" indicates a work item to be looked at as soon as possible (e.g. released work that needs modifications)
let g:todo_next_keyword = [
\ 'FINISH',
\]
let g:todo_next = 1
" indicates an active work item (i.e. work that is not yet ready for release)
let g:todo_now_keyword = [
\ 'FIXME',
\ 'TODO',
\ 'FIX',
\]
let g:todo_now = 1
let g:todo_all = 0

"TODO: perform syntax injection like vim-rainbow to make all TODO labels show up in every language
"TODO: use a config variable to set the lookup engine
"TODO: actually infer prefix expression from g:todo_prefix (requires escape processing)
fun! TodoKeywords(...) abort
  let l:options = get(a:, 1, {})
  if !has_key(l:options, 'now')
    let l:options.now = g:todo_now
  endif
  if !has_key(l:options, 'next')
    let l:options.next = g:todo_next
  endif
  if !has_key(l:options, 'later')
    let l:options.later = g:todo_later
  endif
  if !has_key(l:options, 'warning')
    let l:options.warning = g:todo_warning
  endif
  if !has_key(l:options, 'note')
    let l:options.note = g:todo_note
  endif
  if !has_key(l:options, 'all')
    let l:options.all = g:todo_all
  endif
  let l:keywords = []
  "TODO: add options to search only specific keyword types
  if l:options.now || l:options.all
    let l:keywords += g:todo_now_keyword
  endif
  if l:options.next || l:options.all
    let l:keywords += g:todo_next_keyword
  endif
  if l:options.later || l:options.all
    let l:keywords += g:todo_later_keyword
  endif
  if l:options.warning || l:options.all
    let l:keywords += g:todo_warning_keyword
  endif
  if l:options.note || l:options.all
    let l:keywords += g:todo_note_keyword
  endif
  return l:keywords
endfun

fun! TodoExpression(...) abort
  "FIXME: use re2, not pcre2
  let l:options = get(a:, 1, { 'engine': 'pcre2' })
  if l:options.engine == 'pcre2'
    return '^(?:\s|#|//|/\*|"|!)+(?:'.join(TodoKeywords(l:options), '|').')[[:punct:]]*(?:\(.*\))?(?:[[:punct:]]|\s|$)'
  else
    return '\v\C^%(\s|#|\/\/|\/\*|"|!)+%('.join(TodoKeywords(l:options), '|').')[:punct:]*%(\(.*\))?%([:punct:]|\s|$)'
  endif
endfun

fun! Todo(options, extra_args) abort
  let l:options = a:options
  let l:extra_args = a:extra_args
  let l:grep_expr = ((l:options.loc) ? 'l': '').'grep'.((l:options.add) ? 'add' : ''). l:options.bang
  let l:todo_expr = TodoExpression({ 'engine': 'pcre2' })
  let l:ack_args = shellescape(l:todo_expr) . ' ' . l:extra_args
  if l:options.from_search
    call ack#AckFromSearch(l:grep_expr, l:ack_args)
  elseif l:options.scope == 'window'
    call ack#AckWindow(l:grep_expr, l:ack_args)
  else
    call ack#Ack(l:grep_expr, l:ack_args)
  endif
endfun

command! -bang -nargs=* -complete=file Todo           call Todo({ 'bang': '<bang>', 'add': 0, 'loc': 0, 'scope': 'project', 'from_search': 0 }, <q-args>)
command! -bang -nargs=* -complete=file TodoAdd        call Todo({ 'bang': '<bang>', 'add': 1, 'loc': 0, 'scope': 'project', 'from_search': 0 }, <q-args>)
command! -bang -nargs=* -complete=file TodoFromSearch call Todo({ 'bang': '<bang>', 'add': 0, 'loc': 0, 'scope': 'project', 'from_search': 1 }, <q-args>)
command! -bang -nargs=* -complete=file LTodo          call Todo({ 'bang': '<bang>', 'add': 0, 'loc': 1, 'scope': 'project', 'from_search': 0 }, <q-args>)
command! -bang -nargs=* -complete=file LTodoAdd       call Todo({ 'bang': '<bang>', 'add': 1, 'loc': 1, 'scope': 'project', 'from_search': 0 }, <q-args>)
command! -bang -nargs=*                TodoWindow     call Todo({ 'bang': '<bang>', 'add': 0, 'loc': 0, 'scope':  'window', 'from_search': 0 }, <q-args>)
command! -bang -nargs=*                LTodoWindow    call Todo({ 'bang': '<bang>', 'add': 0, 'loc': 1, 'scope':  'window', 'from_search': 0 }, <q-args>)
"TODO: add a custom quickfix syntax and commands/mappings to make the search results easier to filter/jump/etc.
"      (compare with https://github.com/Dimercel/todo-vim)
"     Dimercel's plugin actually parses each todo line into a descriptor to figure out the type, but it doesn't allow filtering the list by type.
"     Would be nice to have both search-by-type and filter-by-type, but 'ag' returns results on the next line from the keyword, so it's not that easy to do filtering.

"TODO: write a proper unit test
" TEST: try running :TodoWindow right here and make sure all of the below are highlighted
"DEPRECATED
"ATTENTION
"OPTIMIZE
"REFACTOR
"BUGFIX
"COMBAK
"FINISH
"README
"REVIEW
"DEBUG
"FIXME
"ATTN
"HACK
"NOTE
"TEST
"TEMP
"TODO
"TODO(@benmundt): this should also work
"BUG
"FIX
"HEY
"TBD
"WTF!
"XXX
"NB

" TEST: none of the following lines should be found
"DEPRECATEDED
"ATTENTIONS!
"OPTIMIZED
"REFACTORED
"BUGFIXES
"FINISHED
"REVIEWERS
"DEBUGGER
"HACKED
"NOTES
"TESTED
"TEMPORAL
"TODONT
"TODO(@benmundt
"BUGS
