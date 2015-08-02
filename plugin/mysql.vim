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

noSQL = 'No SQl in current cursor position?...'
infoDic = {
    'mySQLcmd' : '',
    'defaultFile'  : 'myfile.txt'
}
outPutFile = ''
sql = ''
filename= vim.eval("g:currentMySQL").replace(' ','\\ ')
f = open(filename)
textList = []
for xline in f.readlines():
    line = xline.strip()
    #    if not line:
    #    line = delim
    textList.append(line)
    if ':' in line:
        xkey, value = line.split(':')
        key = xkey.strip()
        if key in infoDic:
            infoDic[key] = value.strip()
f.close()

if not infoDic['mySQLcmd']:
    print 'No mySQLcmd...'
else:
    row,col = vim.current.window.cursor
    if row < 4:
        print noSQL
    else:
        # istartPos --------------------------------------------------------------
        irow = row - 1
        istartPos = 0
        for i in xrange(irow, 0, -1): 
            if not textList[i]:
                istartPos = i + 1
                break
        # get [filename] + SQL ---------------------------------------------------
        sqlList = []
        for i in xrange(istartPos, len(textList) - 1, 1):
            line = textList[i]
            if not line:
                break
            sqlList.append(line)
        if not sqlList:
            print noSQL   
        elif ':' in sqlList[0]:
            outPutFile = sqlList[0]
            sqlList = sqlList[1:] 
        if not outPutFile:
            outPutFile = infoDic['defaultFile']
        if sqlList:
            print 'outPutFile=%s' % outPutFile 
            sqlList = [line for line in sqlList if line[0] != '#']
            print '¥n'.join(sqlList)

# Todo:
# 1.Get Selected lines or get paragraph
# 2.Check if has outPutFile
# 3.Issue mySQLcmd and save to outPutFile

#print 'infoDic=%s' % infoDic

print(' ')
EOF
endfunction

command! MySQL call s:MySQL()

autocmd BufEnter *.mysql let g:currentMySQL = expand('%:p')
