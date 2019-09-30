# Install Flux

Flux Architecture:

![Flux Architecture](https://github.com/fluxcd/flux/raw/18e5174581f44ed8c9a881dd5071179eed1ebf4d/docs/_files/flux-cd-diagram.png
 "Flux Architecture")

Create git repository which will be used by Flux in GitHub:

```bash
hub create -d "Flux repository for k8s-sockshop" -h "https://ruzickap.github.io/k8s-sockshop/" ruzickap/k8s-flux-repository
```

Output:

```text
A git remote named 'origin' already exists and is set to push to 'ssh://git@github.com/ruzickap/k8s-sockshop.git'.
https://github.com/ruzickap/k8s-flux-repository
```

Clone the git repository:

```bash
mkdir tmp
if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi
git config --global user.email "petr.ruzicka@gmail.com"
git -C tmp clone git@github.com:ruzickap/k8s-flux-repository.git
```

Output:

```text
Cloning into 'k8s-flux-repository'...
warning: You appear to have cloned an empty repository.
```

Create initial Flux repository structure and add it into the git repository:

```bash
cp -v files/flux-repository/README.md tmp/k8s-flux-repository/
mkdir -v tmp/k8s-flux-repository/{namespaces,releases,workloads}

git -C tmp/k8s-flux-repository add .
git -C tmp/k8s-flux-repository commit -m "Initial commit"
git -C tmp/k8s-flux-repository push -q
```

Output:

```text
'files/flux-repository/README.md' -> 'tmp/k8s-flux-repository/README.md'
mkdir: created directory 'tmp/k8s-flux-repository/namespaces'
mkdir: created directory 'tmp/k8s-flux-repository/releases'
mkdir: created directory 'tmp/k8s-flux-repository/workloads'
[master (root-commit) 01ec748] Initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
```

Install [fluxctl](https://docs.fluxcd.io/en/stable/references/fluxctl.html):

```bash
if [ ! -x /usr/local/bin/fluxctl ]; then
  sudo curl -L https://github.com/fluxcd/flux/releases/download/1.14.2/fluxctl_linux_amd64 -o /usr/local/bin/fluxctl
  sudo chmod a+x /usr/local/bin/fluxctl
fi
```

Set the namespace (`flux`) where flux was installed for running `fluxctl`:

```bash
export FLUX_FORWARD_NAMESPACE="flux"
export FLUX_TIMEOUT="30m0s"
```

Obtain the ssh public key through `fluxctl`:

```bash
fluxctl identity
if [ -x /usr/bin/chromium-browser ]; then chromium-browser https://github.com/ruzickap/k8s-flux-repository/settings/keys/new &> /dev/null & fi
```

Output:

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyGvcJPcFxvsc9SHtJiOt7G6pvNQgmcf+PIIfy6PoEvXK2naXmKw68+dtKeIoMzvp63QxoNB+B6qamMbkWqaVCjS4glAXKmf68k/eCazcPNZaQRmL/YUmgmyZ8AF02fDmM/RQMz/2hUtUE6UYs/T5vYUdDwYb09nOmVMgclY6jbmQ4b0OgG18p6RnNYtJ4wysC6+wEoy5xVljKWRE03UxD3pJbVdk5KPcJ/mnX44tUwU/oE/Ezz7LaMjVXnXns8zKu3LOAIeolcCFVJUbUMQhOuvwrXp+Sag1VV3OG4Uy6P3/0wIajEumzHO4GvpAEJ1F1Ny4b692wP/TdUX/WWAIr
```

Add the ssh key to the GitHub "[https://github.com/ruzickap/k8s-flux-repository](https://github.com/ruzickap/k8s-flux-repository)"
-> "Settings" -> "Deploy keys" -> "Add new" -> "Allow write access"

![Flux logo](https://raw.githubusercontent.com/fluxcd/flux/18e5174581f44ed8c9a881dd5071179eed1ebf4d/docs/_files/flux.svg?sanitize=true
"Flux logo")

-----

## Build container image

Fork the `front-end` repository:

```bash
hub -C tmp clone microservices-demo/front-end
hub -C tmp/front-end fork
```

Prepare Tekton pipelines:

```bash
envsubst < files/flux-repository/workloads/tekton-pipelineresource.yaml > tmp/k8s-flux-repository/workloads/tekton-pipelineresource.yaml
envsubst < files/flux-repository/workloads/tekton-task-pipeline.yaml    > tmp/k8s-flux-repository/workloads/tekton-task-pipeline.yaml
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add pipelines and pipelineresources"
git -C tmp/k8s-flux-repository push -q
sleep 15
fluxctl sync
```

Initiate `PipelineRun` which builds container image form git repository:

```bash
envsubst < files/flux-repository/workloads/tekton-pipelinerun.yaml > tmp/k8s-flux-repository/workloads/tekton-pipelinerun.yaml
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Add pipeline and initiate build process"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

Check if the build of docker image was completed:

```bash
kubectl wait --timeout=30m --for=condition=Succeeded pipelineruns/podinfo-build-docker-image-from-git-pipelinerun
kubectl get pipelineruns podinfo-build-docker-image-from-git-pipelinerun
```

Output:

```text
NAME                                              SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
podinfo-build-docker-image-from-git-pipelinerun   True        Succeeded   7m48s       2m30s
```
