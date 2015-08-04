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
from fabric import tasks
from fabric.api import run, env
from fabric.network import disconnect_all 
from fabric.context_managers import settings, hide

env.use_ssh_config = True 

# ----------------------------------------------------------------------------
noSQL = 'No SQl in current cursor position?...'
infoDic = {
    'mySQLcmd':    '',
    'dbHost':      '',
    'defaultFile': 'myfile.txt'
}
outPutFile = ''
comment    = ''
sql        = ''  

# ----------------------------------------------------------------------------
def _shell_escape(string):
    for char in ('"', '$', '`'):
        string = string.replace(char, '\%s' % char)
    return string  

# ----------------------------------------------------------------------------
def run_cmd(cmd, outPutFile):
    env.hosts = [infoDic['dbHost']]
    with settings(hide('warnings', 'running', 'stdout', 'stderr')):
        # print('cmd=%s' % cmd)
        res = run(cmd).replace('\r', '')
        # print('res=\n%s' % res)
        with open(outPutFile, 'w') as f:
            f.write(res)

# ----------------------------------------------------------------------------
filename= vim.eval("g:currentMySQL").replace(' ','\\ ')
with open(filename) as f:
    textList = []
    for xline in f.readlines():
        line = xline.strip()
        #    if not line:
        #    line = delim
        textList.append(line)
        if ':' in line:
            xkey, value = line.split(':')[:2]
            key = xkey.strip()
            if key in infoDic:
                infoDic[key] = value.strip()

if not infoDic['mySQLcmd'] or not infoDic['dbHost']:
    print 'No mySQLcmd or dbHost...'
else:
    row,col = vim.current.window.cursor
    if row < 4:
        print noSQL
    else:
        print 'started...'
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
        # print('sqlList1=%s' % str(sqlList)) # testIto
        if not sqlList:
            print noSQL 
        # print('sqlList[0]=%s' % sqlList[0]) # testIto
        if sqlList and sqlList[0].startswith('#'):
            comment = sqlList[0]
            sqlList = sqlList[1:]
            # print('sqlList2=%s' % str(sqlList)) # testIto
        if sqlList and ':' in sqlList[0]:
            outPutFile = sqlList[0].replace(':','')
            sqlList = sqlList[1:]
            # print('sqlList3=%s' % str(sqlList)) # testIto
        if not outPutFile:
            outPutFile = infoDic['defaultFile']
        if sqlList:
            # print 'outPutFile=%s' % outPutFile 
            sqlList = [line for line in sqlList if line[0] != '#']
            sql = ' '.join(sqlList)
            # sql = sql.replace("'", "\\'").replace('""', '\\"')
            sql = _shell_escape(sql)
            print(sql)
            cmd = infoDic['mySQLcmd'].format(sql=sql)
            tasks.execute(run_cmd, cmd, outPutFile)
            disconnect_all() # Call this when you are done, or get an ugly exception!

print(' ')
EOF
endfunction

command! MySQL call s:MySQL()

autocmd BufEnter *.mysql let g:currentMySQL = expand('%:p')
autocmd FileType   mysql setlocal commentstring=#\ %s 
