#!/bin/bash

source _config.sh

# ===================================================== #
# Global variables:
#    WORKERS_NUMBER    = from _config.sh (how many workers)
#    workers_running   = array with worker status
#    line_id           = line number read from file
#    size              = number of all lines in file
# ===================================================== #

function initialize_workers_status () {
  local size
  local worker_id
  for worker_id in $(seq 0 $[$WORKERS_NUMBER-1])
    do
      workers_running[$worker_id]="x"
    done
}

# ===================================================== #
function backup_workers_files () {
  local fname
  local worker_id

  if [ ! -d "${WORKER_BACKUP_DIR}" ] ; then
    echo "Creating backup directory: ${WORKER_BACKUP_DIR}"
    mkdir ${WORKER_BACKUP_DIR}
  fi

  for worker_id in $(seq 0 $[WORKERS_NUMBER-1])
  do
      for fname in ${WORKER_RUNNING_FILE}_${worker_id} ${WORKER_ERROR_FILE} ${WORKER_LOG_FILE}_${worker_id}
      do
        if [ -e $fname ] ; then
          echo "- moving $fname to ${WORKER_BACKUP_DIR}/"
          mv -f $fname ${WORKER_BACKUP_DIR}
        fi
      done
  done
  echo ""
}

# ===================================================== #
# checks how many workers are still running
# this done by checking existence of file
# returns global array: workers_running
# and exit code, which tells the number of running ones
function update_workers_status () 
{
  local counter=0
  local status
  local worker_id 
  for worker_id in $(seq 0 ${WORKERS_NUMBER})
    do
      START_FILE=${WORKER_RUNNING_FILE}_${worker_id}
      if [ -e $START_FILE ] ; then
        status=`cat $START_FILE`
        workers_running[$worker_id]=$status
        counter=$[$counter+1]
      else
        workers_running[$worker_id]="x"
      fi
    done
    return $counter
}

# ===================================================== #
function get_first_id_of_unoccupied_worker ()
{
  local array_size
  array_size=${#workers_running[*]}
  let array_size--

  for ((i=0 ; i<$array_size ; i++))
    do
      if [[ ! -z "${workers_running[$i]}" && "${workers_running[$i]}" == "x"  ]]; then
        return $i
      fi
    done
  return -1
}

# ===================================================== #
function print_status () 
{
  local array_size
  array_size=${#workers_running[*]}
  let array_size--

  for ((i=0 ; i<$array_size ; i++))
    do
      echo -n "worker: $i "
      if [[ ! -z "${workers_running[$i]}" && "${workers_running[$i]}" == "x"  ]]; then
        echo "unoccupied"
      else 
        echo "running = ${workers_running[$i]}"
      fi
    done
    echo ""
}

# ===================================================== #
function launch_workers ()
{
  local running_workers
  update_workers_status
  running_workers=$?

  while  [ $running_workers -lt $WORKERS_NUMBER ] ;
  do
    if  read -u 3 line ; then
      start_worker $line &
      line_id=$((line_id+1))
    else 
      return 1
    fi

    # if all lines read then finish
    if [ $line_id -gt $size ] ; then 
      return 1
    fi

    sleep 2     # give time for creating locking files
    update_workers_status
    running_workers=$?
  done
}

# ===================================================== #
# waits until there is busy worker changes status to unoccupied
function wait_till_some_unoccupied
{
  local running_workers
  local tmp

  update_workers_status
  running_workers=$?

  # wait until one of the workers finishes the work
  while [ $running_workers -eq $WORKERS_NUMBER ]  ; 
  do
    echo -n "."
    if  read -s -t 1 tmp ; then
      echo ""
      print_status
    fi;

    update_workers_status
    running_workers=$?
  done
  echo ""
}

function wait_till_all_finish ()
{
  local running_workers
  while true ; do 
    echo -n "."
    update_workers_status
    running_workers=$?
    if [ $running_workers -eq 0 ]; then
      echo "."
      return 0
    fi;
    if  read -s -t 1 tmp ; then
      echo ""
      print_status
    fi;
  done
}
