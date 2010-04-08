# Name of this file
CONFIG_FILE="_config.sh"

# IMPORTANT: numbers of workers / threads
WORKERS_NUMBER=3

# where to store files
WORKER_RUNNING_FILE="worker_running"
WORKER_LOG_FILE="worker_stdout"
WORKER_ERROR_FILE="worker_error"

# ============================================== #
# DO NOT EDIT BELLOW
# ============================================== #

# this will remeber line number & it's used to stop parsing this file
STOP_PARSE=$LINENO

# ============================================== #
# Automatically create copies of vars with full path.
# It applies only to vars which in name have FILE or DIR keywoard.

# For example for this variable
# -> DB_WORKER_FILE=data/db
# It will create automatically such variable:
# -> DB_WORKER_FILE_FULL=/tmp/data/db
# ============================================== #

TMPFILE=`mktemp`
# open file descriptor (number 3) with this file
exec 3<$CONFIG_FILE
for ((i=1 ; i<$STOP_PARSE; i++)) 
  do
    if  read -u 3 line ; then
      echo $line | awk -F= '{if ($1 ~ /FILE|DIR/) print $1"_FULL=\"$PWD/$"$1"\""}' >> $TMPFILE
    else
      echo "Error when reading file $CONFIG_FILE , line number: $i"
      return 1
    fi
  done
# close fid
exec 3<&-

source $TMPFILE
rm -f $TMPFILE

#echo $WORKER_LOG_FILE
#echo $WORKER_LOG_FILE_FULL
