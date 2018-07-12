#!/bin/bash
#!filename=inbash.sh

sh_head(){
cat >> $1 << EOF
#!/bin/bash
#==============================================
#    author:
#    date: `date +"%Y-%m-%d"`
#    description:
#==============================================
EOF
}

py_head(){
cat >> $1 << EOF
#!/bin/env python
#==============================================
#    author:
#    date: `date +"%Y-%m-%d"`
#    description:
#==============================================
EOF
}

file_hanld(){
count=`grep "^#!" $1 | wc -l`
if [ ${count} -eq 0 ] && [ `expr $1 : .*\.sh` -ne 0 ]
then
    sh_head $1
elif [ ${count} -eq 0 ] && [ `expr $1 : .*\.py` -ne 0 ]
then
    py_head $1
else
    echo 'Only support .sh .py now'
    rm -fr $1
    exit 0
fi
}

if [ $# -ne 1 ]
then
    echo "Usage: $0 FILENAME"
    exit 0
elif [ ! -f $1 ]
then
    touch $1
    file_hanld $1
else
    file_hanld $1
fi

