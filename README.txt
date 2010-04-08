These scripts are used to execute several tasks in parallel on multi-cpu, multi-core machine in order to make usage of all resources of CPUs.

Run ./threads.sh to get idea how does it work.

# ----------------------- #
# More detailed description
# ----------------------- #
1. Place your commands to the cmd.lst file.
   - this create a pool of jobs to be execute
2. Run ./threads.sh
   - this takes jobs from the pool and executes them in parallel controlled by
     the number of workers (_config.sh).

The script will take jobs from cmd.lst file and will execute them in a "worker"
framework. The workers will run in parallel. If one will finish the job it
will receive another one from the "cmd.lst" pool of jobs.
The number of workers is setup in "_config.sh" file.

In other words we have constant number of jobs running in parallel (defined by
$WORKER_NUMBER variable).  The jobs are taken from the pool ("cmd.lst").
If one job finish the task next one from the pool is executed.
