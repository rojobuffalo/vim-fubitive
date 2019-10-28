function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:bitbucket_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif
  let path = substitute(a:opts.path, '^/', '', '')
  let domain_pattern = 'bitbucket\.org'
  let domains = exists('g:fugitive_bitbucket_domains') ? g:fugitive_bitbucket_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo_matched = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\%(.\{-\}@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  "
  " Squarespace's hosted Bitbucket projects have different URLs for the git remote address
  " and browser address. This next line substitutes the difference:
  " `{hostname}/scm/cem/{project}` -> `{hostname}/projects/CEM/repos/{project}`
  " TODO: isolate this substitution for only the squarespace root in g:fugitive_bitbucket_domains
  let repo = substitute(repo_matched,'scm/cec/','projects/CEM/repos/','')
  "
  if repo ==# ''
    return ''
  endif
  if index(domains, 'http://' . matchstr(repo, '^[^:/]*')) >= 0
    let root = 'http://' . substitute(repo,':','/','')
  else
    let root = 'https://' . substitute(repo,':','/','')
  endif
  if path =~# '^\.git/refs/heads/'
    return root . '/commits/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/browse/' .path[15:-1]
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.commit =~# '^\d\=$'
    let commit = a:opts.repo.rev_parse('HEAD')
  else
    let commit = a:opts.commit
  endif
  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let url = s:sub(root . '/browse/' . path,'/$','' . '?at=' . commit)
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let url = root . '/browse/' . path . '?at=' . commit
    if get(a:opts, 'line1')
      " let url .= '/' . fnamemodify(path, ':t') . '#' . a:opts.line1
      let url .= '#' . a:opts.line1
      if get(a:opts, 'line2')
        let url .= '-' . a:opts.line2
      endif
    endif
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:bitbucket_url'))
