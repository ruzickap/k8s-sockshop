# Sockshop

Deploy Sockshop:

```bash
envsubst < files/flux-repository/namespaces/sockshop.yaml > tmp/k8s-flux-repository/namespaces/sockshop.yaml
envsubst < files/flux-repository/workloads/sockshop.yaml > tmp/k8s-flux-repository/workloads/sockshop.yaml
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Sockshop added"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

Check the commit and open the `index.html` in the web browser:

```bash
if [ -x /usr/bin/chromium-browser ]; then
  chromium-browser \
    https://github.com/ruzickap/k8s-flux-repository/blob/master/workloads/sockshop.yaml#L201-L337 \
    https://github.com/ruzickap/front-end/edit/master/public/index.html \
  &> /dev/null &
fi
```

Open few tabs in web browser:

```bash
if [ -x /usr/bin/falkon ]; then
  falkon "https://sockshop.${MY_DOMAIN}" &> /dev/null &
  falkon "https://tekton-dashboard.${MY_DOMAIN}/#/pipelineruns" &> /dev/null &
  falkon "https://flagger-grafana.${MY_DOMAIN}/d/flagger-istio/istio-canary?orgId=1&refresh=5s" &> /dev/null &
  falkon "https://kiali.${MY_DOMAIN}/console/graph/namespaces/?edges=requestsPercentage&graphType=app&namespaces=sock-shop&unusedNodes=false&injectServiceNodes=true&pi=15000&duration=60&layout=dagre" &> /dev/null &
fi
```

Modify the [https://github.com/ruzickap/front-end/edit/master/public/index.html](https://github.com/ruzickap/front-end/edit/master/public/index.html)
and change something visible on the first page.

-----

Initiate build of a new container:

```bash
sed 's/podinfo-build-docker-image-from-git-pipelinerun/podinfo-build-docker-image-from-git-pipelinerun-2/' tmp/k8s-flux-repository/workloads/tekton-pipelinerun.yaml > tmp/k8s-flux-repository/workloads/tekton-pipelinerun-2.yaml
sed -i 's/0.3.12/0.4.0/' tmp/k8s-flux-repository/workloads/tekton-pipelineresource.yaml
git -C tmp/k8s-flux-repository diff
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Start building the front-end container"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

Open the Tekton Dashboard page [https://tekton-dashboard.myexample.dev](https://tekton-dashboard.myexample.dev)
to see the build process.

Run tmux session with monitoring commands:

```bash
tmux new-session \; \
send-keys "\
  while true ; do
  fluxctl list-images -n sock-shop --workload sock-shop:deployment/front-end ;
  sleep 5 ;
  done
" C-m \; \
split-window -v -p 50 \; \
send-keys "kubectl -n istio-system logs deployment/flagger -f | jq .msg" C-m \; \
split-window -h -p 30 \; \
send-keys "while true ; do kubectl -n sock-shop get canaries sockshop; sleep 3; done" C-m \; \
select-pane -t 0 \; \
split-window -h -p 37 \; \
send-keys "while true; do kubectl get -n sock-shop canary/sockshop -o json | jq .status; sleep 2; done" C-m \; \
set-option status off
```
