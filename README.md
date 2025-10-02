# REANNZ training environment for MPI Bioinformatics app

JupyterLab app for running MPI Shell for Bioinformatics on the NeSI training environment.

### Workshop Material
https://genomicsaotearoa.github.io/hts_workshop_mpi/

### Tools List
* fastqc
* fastp
* pycoQC
* NanoFlit
* porechop
* seqkit

###  Manual Changes after deployment
dataset is large ~2Gb and does not store on git or containerised and requires manual upload.
login in as `trainer1` and upload a tar.gz file of the workshop material followed by a loop to copy all data to training accounts and then also for the trainer accounts, modify as required.

``` bash
for i in $(seq 1 10)
do
    echo copying to training$i
    cp level1.tar.gz /home/shared/training$i
    tar -xzf /home/shared/training$i/level1.tar.gz -C /home/shared/training$i
    rm /home/shared/training$i/level1.tar.gz
    chmod -R go+rw /home/shared/training$i/level1
done
```
Permissions for `trainer` accounts don;t allow the copying, so all trainer account must upload and then run the following.

``` bash
tar -xzf /home/shared/trainer1/level1.tar.gz -C /home/shared/trainer1
rm /home/shared/trainer1/level1.tar.gz
```



