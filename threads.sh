#!/bin/bash

source ~/fpga-setup.sh
source libmanager.sh

# ===================================================== #
# Start single worker. Creates file with pid of that process.
# This is runned in background.
function start_worker() {

  # ============================================== #
  function run_task () {
    local letter=$1
    # write mesg for manager & process stdout file 
    status_mesg="${status_line}[${letter}] ${params}"
    printf "\n$status_mesg\n"
    printf "\n\nSTART: `date`\n$status_mesg\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}

    # launch process 
    ( eval $cmd ) >>${WORKER_LOG_FILE_FULL}_${worker_id} 2>&1
   if [ $? != 0 ] ; then 
          # when error happend during compilation
          echo "${status_line}[${letter}] error"
          echo "${status_mesg}" >> ${WORKER_ERROR_FILE_FULL}
          # release worker - mark it as unoccupied
          rm -f $lock_file && sync
          exit 1
    fi
    printf "END:  `date`\n\n\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}
  }
  # ============================================== #

  local worker_id
  local bg_pid
  local lock_file
  local status_line
  local status_mesg
  local config_input
  local compile_dir
  local db_file
  local rowid

  get_first_id_of_unoccupied_worker
  worker_id=$?

  # get pid of this background process
  bg_pid=$!
  if [ -z $bg_pid ]; then 
     bg_pid=$$
  fi

  lock_file=${WORKER_RUNNING_FILE_FULL}_${worker_id}
  status_line=`printf "[w:%d|pid:%5d|line:%d/%d]" $worker_id $bg_pid $line_id $size`
  

  # mark worker as occupied (busy) 
  # save pid and other infos to the lock_file
  echo $status_line > $lock_file && sync

  save_pwd=$PWD

  cmd=$*
  run_task c 
  
  printf "END:  `date`\n\n\n" >> ${WORKER_LOG_FILE_FULL}_${worker_id}
  cd $save_pwd

  # release worker - mark it as unoccupied
  rm -f $lock_file && sync
}

# ===================================================== #
function main ()
{
  # find . -type f -name db_store.txt | xargs grep CP_HAS_PADS   | wc -l

  for FILENAME in cmd.lst
  do
    if [ ! -e $FILENAME ] ; then
      echo "Error: File $FILENAME dos not exists" >&2
      exit
    fi

    # check which numbers are already generatored

    size=`wc -l $FILENAME | awk '{print $1}'`
    exec 3<$FILENAME # open fid

    line_id=1
    initialize_workers_status
    while true ; 
    do
      launch_workers
      if [ $? -eq 1 ] ; then
        sleep 1
        echo ""
        echo "No more data in ${FILENAME}. Waiting till all workers will finish their work"
        wait_till_all_finish
        echo "Done."
        break
      fi;
      wait_till_some_unoccupied
    done

    exec 3>&-     # close fid
  done
}

# ===================================================== #
main
