limit=200
dir=/rdfs1/handoffToQA/integrity/11.x/1/builds
cd $dir

LOG=${HOME}/log/cleanup_sda2__`date +%Y%m%d_%H%M%S`.log

if [ "$?" = "0" ];
then
disk_space=`df -h | grep -w /sda2 | awk '{ print $4 }'| sed 's/G//'`
 else
        echo "Cannot change directory!" 1>&2
        exit 1
fi
cleanup=0

function fn_do_log
{
msg=$1
dt=`date +'%r'`
echo "${dt} : ${msg}" | tee -a ${LOG}
}

function fn_do_cleanup
{
bld_prd=$1
cur_dir=`pwd`

count=`ls -lrt | grep ^d | grep -v ${bld_prd} | grep -v midday | tail -n+1 | wc -l`
    if [ "$count" -gt 10 ]
    then
     dirs=`ls -lrt | grep ^d | grep -v ${bld_prd} | grep -v midday | tail -n+1 | head -10 | awk '{print $9}'`
     for i in $dirs
     do
               fn_do_log "Removing ${i} in ${cur_dir}..."
       rm -r  "$i"
               if [ $? -eq 0 ]
               then
                              fn_do_log "Removing ${i} in ${cur_dir}... Succeeded"
               else
                              fn_do_log "Removing ${i} in ${cur_dir}... Failed"
               fi
     done
     cleanup=1
     elif [ "$count" -eq 10 ]
    then
    dirs=`ls -lrt | grep ^d | grep -v ${bld_prd} | grep -v midday | tail -n+1 | head -9 | awk '{print $9}'`
      for i in $dirs
     do
               fn_do_log "Removing ${i} in ${cur_dir}..."
       rm -r  "$i"
               if [ $? -eq 0 ]
               then
                    fn_do_log "Removing ${i} in ${cur_dir}... Succeeded"
                else
                    fn_do_log "Removing ${i} in ${cur_dir}... Failed"
                   fi
     done
     cleanup=1
     elif [ "$count" -le 9  -a  "$count" -ne 0 ]
     then
      dirs=`ls -lrt | grep ^d | grep -v ${bld_prd} | grep -v midday | tail -n+1 | head | awk '{print $9}'`
      for i in $dirs
     do
               fn_do_log "Removing ${i} in ${cur_dir}..."
       rm -r  "$i"
               if [ $? -eq 0 ]
                then
                   fn_do_log "Removing ${i} in ${cur_dir}... Succeeded"
                else
                fn_do_log "Removing ${i} in ${cur_dir}... Failed"
                fi
    done
cleanup=1
     else
            echo "" | tee -a ${LOG}
     fi
}

if [ "$disk_space" -lt $limit ]
then
    fn_do_log "Availble space on /sda2:$disk_space G is less then 200G and then start cleaning"

# Cleanup 1

fn_do_cleanup 961

   if [ -d midday ]
   then
      cd midday

       echo "" | tee -a ${LOG}

    # Cleanup 2

    fn_do_cleanup 959

else
               echo "" | tee -a ${LOG}
     echo "midday dir is not existed" | tee -a ${LOG}
    fi

#
#
   if [ "$cleanup" -eq 1 ]
   then
       usage_space=`df -h | grep -w /sda2 | awk '{ print $4 }'| sed 's/G//'`
         if [ "$usage_space" -lt "$limit" ]
         then
              fn_do_log  "Free space availbile on /sda2:$usage_space G and it's less then 200G after cleanup"
         else
              fn_do_log  "Free space availble on /sda2:$usage_space G and it's greater then 200G after cleanup"
          fi
   else
      fn_do_log  "nothing can be deleted and cleanup need to be done manually"
    fi
else
      fn_do_log  "Availble space on /sda2:$disk_space G is greater then 200G and please check further and take necessary action"
fi


export NOTIFY="hadabala@ptc.com"
export RETURN="hadabala@ptc.com"
if [ "$cleanup" -eq 1 ]
then
mailx -r ${RETURN} -s "Cleanup report of /rdfs1" ${NOTIFY} <<EOF
`cat ${LOG}`

Thanks,
builder
else
    echo  " "
fi
