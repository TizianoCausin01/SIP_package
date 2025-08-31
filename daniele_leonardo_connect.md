# Leonardo for dummy VsCode users

## Connecting to Leonardo (2FA):
1. Connect to Leonardo and start 2FA
[Bash/Powershell terminal inside or outside VSCode]
```bash
step ssh login dtirinna@sissa.it --provisioner cineca-hpc
```
2. Perform 2FA
[Password (online) -> Google authenticator (phone)]

3. Connect to remote
[Open VSCode and connect to remote named "leonardo"]

## Interactive session:
5. Request allocation of resources
[Bash terminal in VSCode]
```bash
salloc --nodes=1 --gres=gpu:1 --mem=32G --ntasks=1 --cpus-per-task=4 -A Sis24_piasini -p boost_usr_prod --time=01:00:00
```

5.1 Specify debugging mode when requesting allocation of resources (higher priority is given to jobs that require maximum 2 nodes / 64 cores / 8 GPUs)
[Bash terminal in VSCode (add to line above)]
```bash
--qos=boost_qos_dbg
```

(...when node is ready for job...)

6. Connect to assigned node
[Bash terminal in VSCode]
```bash
ssh lrdn ...
```

7. Activate virtual environment
[Bash terminal in VSCode]
```bash
source virtualenvs/dl/bin/activate
```

8. Run script
[Bash terminal in VSCode]
```bash
python main.py
```

9. Launch Tensorboard session
[In VSCode, simply launch it from the script where Tensorboard is called, specifying the folder. This session is (probably) running in the login node]

10. Log out from compute node and go back to login node
[Bash terminal in VSCode]
Ctrl+D

11. Go back to assigned node
[Bash terminal in VSCode]
```bash
ssh lrdn ...
```

12. Kill interactive session (NOTE: save work before killing!)
[Bash terminal in VSCode]
Ctrl+D

## Non-interactive session:
5. Configure jobscript file (in this case, the file named "grid_exp_jobscript.sh" is saved in "scripts" folder)
Template:
```bash
#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --mem=32G
#SBATCH --account=Sis24_piasini       # account name
#SBATCH --partition=boost_usr_prod # partition name
#SBATCH --job-name=grid_exp
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dtirinna@sissa.it
#SBATCH --output=/leonardo/home/userexternal/dtirinna/HUPLACLIP-NNs/out/%x.%j.out   # file name will be *job_name*.*job_id*
#SBATCH --error=/leonardo/home/userexternal/dtirinna/HUPLACLIP-NNs/out/%x.%j.err    # file name will be *job_name*.*job_id*

source $HOME/virtualenvs/dl/bin/activate

cd $HOME/HUPLACLIP-NNs/
# cd $SLURM_SUBMIT_DIR

srun --unbuffered time python main.py
```

5.1. Specify debugging mode when requesting allocation of resources (higher priority is given to jobs that require maximum 2 nodes / 64 cores / 8 GPUs)
[Bash terminal in VSCode (add to snippet above)]
```bash
--qos=boost_qos_dbg
```

6. Run jobscript
[Bash terminal in VSCode. Navigate to "scripts" folder and run this from terminal]
```bash
sbatch grid_exp_jobscript.sh
```

7. Visualizing state of jobs
[Bash terminal in VSCode]
```bash
squeue --user=dtirinna
```

8. Visualizing state of cluster partitions (to evaluate load. Separates nodes into "Allocated/Idle/Other/Total")
```bash
sinfo -o "%10D %20F %P"
```
(... once job has started ...)

9. Monitor resource usage on assigned node (TO CHECK)
    9.1 Connect to assigned node:
    ```bash
    ssh lrdn ...
    ```
    9.2 Check gpu status of assigned node (htop INSTALLED BY DEFAULT?)
    ```bash
    nvtop / htop
    ```

## Bash commands:
- `rm -r` -> to delete PERMANENTLY (no bin)
- `./` -> find executable file in the specified folder
- `which` + command -> to print where the specified executable file is located
- `echo` + string -> similar to print
- `$` + variable -> to access the content of a variable (for example $PATH or $HOME)
- `ls -a` list all files (also the hidden ones, preceded by a dot)
- `less` + file_name -> visualizing text file in terminal
- `tail` + file_name -> visualizing end of text file in terminal
- `time` + command -> time needed to execute the command ("user" entry is the relevant one)

## Software carpentry notes:
- top / htop / nvtop -> for resource monitoring on Linux systems;
- On Linux, it is possible to install programs by installing Ubuntu's official repositories (similar to Play Store), or by compiling the source code on the machine. To do so, a compiler is necessary: a compiler translates the source code in code that can be read by the machine.
- Cmake is a system that controls the dependencies. From now on, every time I use "make install" to install third party software (compiled from the source code), the destination should be "home/local". For example, with cmake, I should specify "cmake -DCMAKE_INSTALL_PREFIX=/usr" OR "prefix = $HOME/local"
- Files and folders preceded by a dot (for instance ".config") are configuration files, usually hidden, can be seen by typing "ls -a"
- When a script is executed, it can produce two types of output: standard output / standar error. When launching a jobscript, the location of these files should be specified, together with an indication of job name and of the job id (\out folder tends to become messier and messier!)

## References:
- Leonardo - Booster user guide (https://wiki.u-gov.it/confluence/display/SCAIUS/UG3.2.1%3A+LEONARDO+Booster+UserGuide)
- Leonardo + slurml (https://wiki.u-gov.it/confluence/plugins/servlet/mobile?contentId=262242562#content/view/262242562)
- Slurm commands (https://slurm.schedmd.com/)

## Stuff to check out:
- Lab wiki (https://people.sissa.it/~epiasini/wiki/doku.php?id=start)
- terminal multiplexers ([Lab Wiki](https://people.sissa.it/~epiasini/wiki/doku.php?id=recommended-tools#terminal_multiplexingtmux))
- tutorial Leonardo ([Lab Wiki](https://people.sissa.it/~epiasini/wiki/doku.php?id=using-leonardo))
- tutorial Slurm ( https://wiki.u-gov.it/confluence/display/SCAIUS/UG2.6.1%3A+How+to+submit+the+job+-+Batch+Scheduler+SLURM )
