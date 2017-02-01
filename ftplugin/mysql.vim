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

# ----------------------------------------------------------------------------
def run_cmd(cmd, outPutFile, comment):
    with settings(hide('warnings', 'running', 'stdout', 'stderr')):
        res = run(cmd).replace('\r', '')
        with open(outPutFile, 'w') as f:
            if comment:
                xcomment = comment
            else:
                xcomment = '# %s' % ('-' * 77)
            f.write('%s\n' % xcomment)
            
            if 'execute=' in cmd:
                f.write('%s\n' % cmd.split('execute=')[1].strip().strip('""')) # Todo: more flexible...
            f.write(res)
            f.write('\n\n')

# ----------------------------------------------------------------------------
textList = []
for xline in vim.current.buffer[:]:
    line = xline.strip()
    textList.append(line)
    if ':' in line:
        xkey, value = line.split(':')[:2]
        key = xkey.strip()
        if key in infoDic:
            infoDic[key] = value.strip()

if not infoDic['mySQLcmd'] or not infoDic['dbHost']:
    print('mysql.vim, no mySQLcmd or dbHost...')
else:
    row,col = vim.current.window.cursor
    if row < 4:
        print(noSQL)
    else:
        outPutFile = ''
        comment = []

        # istartPos --------------------------------------------------------------
        irow = row - 1
        istartPos = 0
        
        for i in range(irow, 0, -1): 
            if not textList[i]:
                istartPos = i + 1
                break
        # get [filename] + SQL ---------------------------------------------------
        sqlList = []
        for i in range(istartPos, len(textList) - 1, 1):
            line = textList[i]
            if not line:
                break
            if ':' in line and '.txt' in line:
                outPutFile = line.replace(':', '')
                continue
            if line.startswith('#'): 
                comment.append(line)
                continue
            sqlList.append(line)
        if not sqlList:
            print(noSQL) 
        if not outPutFile:
            outPutFile = infoDic['defaultFile']
        if sqlList:
            # sqlList = [line for line in sqlList if line[0] != '#']
            sql = '\n'.join(sqlList).replace('"', "'") # 
            # print(sql)
            env.hosts = [infoDic['dbHost']]
            cmd = infoDic['mySQLcmd'].format(sql=sql)
            try:
                tasks.execute(run_cmd, cmd, outPutFile, '\n'.join(comment))
            finally:
                disconnect_all() # Call this when you are done, or get an ugly exception!

print(' ')
EOF

endfunction

command! MySQL call s:MySQL()

autocmd BufLeave,FocusLost * echo ' '

setlocal commentstring=#\ %s 
setlocal cmdheight=3

