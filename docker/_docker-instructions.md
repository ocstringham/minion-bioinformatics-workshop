# Set Up Instructions
1. Have Docker Desktop installed and have docker engine running (it will start automatically when docker desktop opens). 
    - You can configure the max number of cores and ram you want it to use. 
    - This is helpful when you are just testing stuff because docker could use all your resources and your computer will become unusably slow.
2. Pull (aka download) image from Docker Hub OR build custom image from a dockerfile
    - see more instructions below
4. Notes: to 'interact' with these images, you need to create a container, which is a running iteration of the image. 
    - The containers will be 'spun up' when you need to use them & stopped when not needed
    - The containers will be attached to a shared 'volume' where the data will live and persist even when containers are stopped or deleted
5. Optional: Create volume where data will be stored and persist
    - in terminal run: docker volume create bioinformatics_data
6. Optional: Create Obitools2 container with attached volume
    - in terminal run: docker run --name obitools2 -v bioinformatics_data:/data romunov/obitools:1.2.13


# Enter custom container to interact with it
- start up container in terminal: 
    docker start bioinformatics
- enter container in terminal: 
    docker exec -it bioinformatics /bin/bash
- note: the volume will be on the root of this container in the data/ folder
- note: to use crabs, you must enter the conda environment using: conda activate crabs_env
- note: to use cutadapt, you must enter the conda environment using: conda activate cutadapt_env
- when done, to exit container type: exit
- when done, stop container in terminal (optional): 
    docker stop bioinformatics_v1


# Other items
* To copy a file from from host computer to docker container (and vice versa) use:
    - from terminal (aka not inside of conatiner BUT container must be running): 
        docker cp <local_directory> <container_name_or_id>:<container_path>
        docker cp C:\Users\oliver\Downloads\wolf_tutorial obitools2:data
    - Note, to transfer to a volume, you must cp to a container with the volume mounted like we already have set up


# Push docker image to docker hub
0. Create a repo in docker hub
1. terminal: docker login
2. docker image tag my-image username/my-repo (docker image tag bioinformatics:0.0.1 olistr12/bioinformatics:0.0.1)
3. docker push username/my-repo:version (docker push olistr12/bioinformatics:0.0.1)

# Update docker image
1. Build new image from dockerfile
2. login & tag & push from above, but update version tag 
    docker image tag bioinformatics:0.0.1 olistr12/bioinformatics:0.0.2
    docker push olistr12/bioinformatics:0.0.2


# Build images from Dockfile

## r w/packages
docker build -t r_env -f docker/r_env.Dockerfile .
docker run -it --name r-test r_env
docker login --username=olistr12 docker.io
docker image tag r_env olistr12/r_env:0.0.6
docker push olistr12/r_env:0.0.6


## vsearch
docker build -t vsearch -f docker/vsearch.Dockerfile .
docker run -it --name vsearch-test vsearch
docker login --username=olistr12 docker.io
docker image tag vsearch olistr12/vsearch:2.28.1
docker push olistr12/vsearch:2.28.1

## cutadapt
docker build -t cutadapt -f docker/cutadapt.Dockerfile .
docker run -it --name cutadapt-test cutadapt
docker login --username=olistr12 docker.io
docker image tag cutadapt olistr12/cutadapt:4.9
docker push olistr12/cutadapt:4.9