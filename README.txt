This scripts are used to execute several tasks in parallel on multi-cpu, multi-core machine in order to make usage of all resources of CPUs.

The list of all jobs to executed is kept in the "cmd.lst" file.
Each job is taken and is executed with worker which is manage by the script.
The number of workers and logfiles are configured from "_config.sh" file.

Run ./threads.sh in order to get idea how does it work.
