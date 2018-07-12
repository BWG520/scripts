#!/bash/bin 
#!filename=inbash.sh
count=`grep "^#!" $1 | wc -l`
if [ ${count} == 0 ];
then
cat >> $1 << EOF
###########################################
#!/bin/bash
#author:
#date: `date +"%Y-%m-%d"`
#description:
###########################################
EOF

fi
