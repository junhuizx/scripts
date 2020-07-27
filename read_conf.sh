## 定义一个公用的脚本，把常见的函数放到里面，别的脚本就可以引用然后调用
## 类似于面向对象语言的包含文件
vim /devOps/shell/common/functions

#!/usr/bin/env bash
##
## 得到ini配置文件所有的sections名称
## listIniSections "filename.ini"
##
listIniSections()
{
    inifile="$1"
    # echo "inifile:${inifile}"
    # # exit
    if [ $# -ne 1 ] || [ ! -f ${inifile} ]
    then
        echo  "file [${inifile}] not exist!"
        exit
    else
        sections=`sed -n '/\[*\]/p' ${inifile}  |grep -v '^#'|tr -d []`
        echo  "${sections}"
    fi
}

##
## 得到ini配置文件给定section的所有key值
## ini中多个section用空行隔开
## listIniSections "filename.ini" "section"
##
listIniKeys()
{
    inifile="$1"
    section="$2"
    if [ $# -ne 2 ] || [ ! -f ${inifile} ]
    then
        echo  "ini file not exist!"
        exit
    else
        keys=$(sed -n '/\['$section'\]/,/^$/p' $inifile|grep -Ev '\[|\]|^$'|awk -F'=' '{print $1}')
        echo ${keys}
    fi
}

##
## 得到ini配置文件给定section的所有value值
## ini中多个section用空行隔开
## listIniSections "filename.ini" "section"
##
listIniValues()
{
    inifile="$1"
    section="$2"
    if [ $# -ne 2 ] || [ ! -f ${inifile} ]
    then
        echo "ini file [${inifile}]!"
        exit
    else
        values=$(sed -n '/\['$section'\]/,/^$/p' $inifile|grep -Ev '\[|\]|^$'|awk -F'=' '{print $2}')
        echo ${values}
    fi
}

##
## 得到ini配置文件给定section的所有key - value值
## ini中多个section用空行隔开
## listIniSections "filename.ini" "section"
##
listIniKeysValues()
{
    inifile="$1"
    section="$2"
    if [ $# -ne 2 ] || [ ! -f ${inifile} ]
    then
        echo "ini file [${inifile}]!"
        exit
    else
        values=$(sed -n '/\['$section'\]/,/^$/p' $inifile|grep -Ev '\[|\]|^$'|awk -F'=' '{print $1, $2}')
        echo ${values}
    fi
}