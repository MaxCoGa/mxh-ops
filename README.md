# mxh-ops
docker build -t mxh-ops-runner .
docker run --env-file env --privileged -itd --name mxh-ops-runner mxh-ops-runner:latest
docker exec --privileged -it mxh-ops-runner bash
# Use this YAML in your workflow file for each job
runs-on: self-hosted


## build the stack

1. mxh-ops
    - automate everything
    - podman
    - docker
2. mxh-db
    - mongodb
3. mxh-stack
    - backend:
        - currently in python & rust
        - mxh-db
            - mongodb
        - mxh-auth
    - frontend:
        - web based
    - apps:
        - csc
            - mxh-csc[mxh-csc](https://github.com/MaxCoGa/mxh-csc)
        

4. mxh-tor
    - enable tor (optional)


## Podman machine setup (change default location)
podman machine init --cpus 8 --disk-size 40 --memory 16192
podman machine list
podman machine info 

wsl fix: 
cd D:\Podman\
mkdir podman-machine-default
podman machine stop
podman machine stop
wsl --shutdown
wsl --export podman-machine-default podman.tar
wsl --unregister podman-machine-default
wsl --import podman-machine-default podman-machine-default/ podman.tar --version 2
del podman.tar

podman machine start

### Container creation with podman
podman build -f Dockerfile -t mxh-ops-runner
podman run --env-file env --privileged -itd --name mxh-ops-runner mxh-ops-runner:latest
