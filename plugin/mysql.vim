" File: mysql.vim
" Author: Akio Ito
" Version: 0.1

"-----------------------------------------------------------------------------
if has("python3")
    command! -nargs=1 Py py3 <args>
else
    command! -nargs=1 Py py <args>
endif
if !(has('python') || has('python3'))
    echo "Error: Required vim compiled with +python"
    finish
endif
if exists("loaded_mysql")
    finish
endif
let loaded_mysql = 1


"-----------------------------------------------------------------------------
function! s:MySQL()
if !exists("g:currentMySQL")
    return
endif
Py << EOF
import vim 

infoDic = {
    'mySQLcmd' : '',
    'defaultFile'  : 'myfile.txt'
}

filename= vim.eval("g:currentMySQL").replace(' ','\\ ')
f = open(filename)
for xline in f.readlines():
    line = xline.strip()
    if ':' in line:
        xkey, value = line.split(':')
        key = xkey.strip()
        if key in infoDic:
            infoDic[key] = value.strip()
f.close()  
if not infoDic['mySQLcmd']:
    print 'No mySQLcmd...'
    exit()

# Todo:
# 1.Get Selected lines or get paragraph
# 2.Check if has outPutFile
# 3.Issue mySQLcmd and save to outPutFile

print 'infoDic=%s' % infoDic

print(' ')
EOF
endfunction

command! MySQL call s:MySQL()

autocmd BufEnter *.mysql let g:currentMySQL = expand('%:p')
