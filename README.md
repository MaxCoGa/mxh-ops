# mxh-ops
docker build -t mxh-ops-runner .
docker run --env-file env --privileged -itd --name mxh-ops-runner mxh-ops-runner:latest
docker exec --privileged -it mxh-ops-runner bash
# Use this YAML in your workflow file for each job
runs-on: self-hosted