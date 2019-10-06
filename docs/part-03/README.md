# Sockshop

Sockshop Architecture:

![Sockshop Architecture](https://github.com/microservices-demo/microservices-demo.github.io/raw/40d8170161d2f81cc6524f8aa137c8e9f9131ecd/assets/Architecture.png
"Sockshop Architecture")

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
    https://github.com/ruzickap/k8s-flux-repository/commits/master \
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
  falkon "https://kiali.${MY_DOMAIN}/console/graph/namespaces/?edges=requestsPercentage&graphType=app&namespaces=sock-shop&unusedNodes=false&injectServiceNodes=true&pi=15000&duration=60&layout=dagre" &> /dev/null &
fi
```

The application should be ready. Verify the canary deployment details:

```bash
kubectl describe canaries.flagger.app -n sock-shop
```

Output:

```text
Name:         sockshop
Namespace:    sock-shop
Labels:       fluxcd.io/sync-gc-mark=sha256.mR4DMU8yLyj9zNqHpNn1gLLyzpxGA6Bi83LM0mcrWK4
Annotations:  fluxcd.io/sync-checksum: d76bc80bde7011788b9a03cb0d8c15303de6ed0a
              kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"flagger.app/v1alpha3","kind":"Canary","metadata":{"annotations":{"fluxcd.io/sync-checksum":"d76bc80bde7011788b9a03cb0d8c153...
API Version:  flagger.app/v1alpha3
Kind:         Canary
Metadata:
  Creation Timestamp:  2019-09-30T11:52:51Z
  Generation:          1
  Resource Version:    6303
  Self Link:           /apis/flagger.app/v1alpha3/namespaces/sock-shop/canaries/sockshop
  UID:                 d4cbde0d-e378-11e9-aa18-424f651a3093
Spec:
  Canary Analysis:
    Interval:    10s
    Max Weight:  50
    Metrics:
      Interval:               1m
      Name:                   request-success-rate
      Threshold:              99
      Interval:               30s
      Name:                   request-duration
      Threshold:              500
    Step Weight:              5
    Threshold:                10
  Progress Deadline Seconds:  60
  Provider:                   istio
  Service:
    Gateways:
      sockshop-gateway
    Hosts:
      sockshop.myexample.dev
    Port:            8079
    Port Discovery:  false
    Port Name:       http
  Target Ref:
    API Version:  apps/v1
    Kind:         Deployment
    Name:         front-end
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2019-09-30T11:56:02Z
    Last Update Time:      2019-09-30T11:56:02Z
    Message:               Deployment initialization completed.
    Reason:                Initialized
    Status:                True
    Type:                  Promoted
  Failed Checks:           0
  Iterations:              0
  Last Applied Spec:       1708531587231322986
  Last Transition Time:    2019-09-30T11:56:02Z
  Phase:                   Initialized
  Tracked Configs:
Events:
  Type     Reason  Age                   From     Message
  ----     ------  ----                  ----     -------
  Warning  Synced  91s (x19 over 4m31s)  flagger  Halt advancement front-end-primary.sock-shop waiting for rollout to finish: 0 of 1 updated replicas are available
  Normal   Synced  81s                   flagger  Initialization done! sockshop.sock-shop
```

The original deployment `front-end` doesn't have any pods now and new deployment
`front-end-primary` was created by Flagger which takes care about the traffic:

```bash
kubectl get deployment -n sock-shop
```

Output:

```text
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
carts               1/1     1            1           5m2s
carts-db            1/1     1            1           5m2s
catalogue           1/1     1            1           5m2s
catalogue-db        1/1     1            1           5m2s
front-end           0/0     0            0           5m2s
front-end-primary   1/1     1            1           4m59s
orders              1/1     1            1           5m1s
orders-db           1/1     1            1           5m1s
payment             1/1     1            1           5m1s
queue-master        1/1     1            1           5m1s
rabbitmq            1/1     1            1           5m1s
shipping            1/1     1            1           5m1s
user                1/1     1            1           5m1s
user-db             1/1     1            1           5m1s
```

There are three new services created by Flagger - `front-end-canary`
and `front-end-primary`:

```bash
kubectl get services -n sock-shop
```

Output:

```text
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
carts               ClusterIP   10.0.189.70    <none>        80/TCP      5m30s
carts-db            ClusterIP   10.0.106.236   <none>        27017/TCP   5m30s
catalogue           ClusterIP   10.0.105.32    <none>        80/TCP      5m30s
catalogue-db        ClusterIP   10.0.161.107   <none>        3306/TCP    5m30s
front-end           ClusterIP   10.0.222.203   <none>        8079/TCP    5m27s
front-end-canary    ClusterIP   10.0.53.222    <none>        8079/TCP    5m27s
front-end-primary   ClusterIP   10.0.252.82    <none>        8079/TCP    5m27s
orders              ClusterIP   10.0.215.69    <none>        80/TCP      5m30s
orders-db           ClusterIP   10.0.228.160   <none>        27017/TCP   5m30s
payment             ClusterIP   10.0.250.84    <none>        80/TCP      5m30s
queue-master        ClusterIP   10.0.110.68    <none>        80/TCP      5m30s
rabbitmq            ClusterIP   10.0.163.62    <none>        5672/TCP    5m30s
shipping            ClusterIP   10.0.182.48    <none>        80/TCP      5m30s
user                ClusterIP   10.0.185.203   <none>        80/TCP      5m30s
user-db             ClusterIP   10.0.247.233   <none>        27017/TCP   5m30s
```

There is also new `VirtualService`:

```bash
kubectl describe virtualservices.networking.istio.io -n sock-shop
```

Output:

```text
Name:         front-end
Namespace:    sock-shop
Labels:       <none>
Annotations:  <none>
API Version:  networking.istio.io/v1alpha3
Kind:         VirtualService
Metadata:
  Creation Timestamp:  2019-09-30T11:52:52Z
  Generation:          1
  Owner References:
    API Version:           flagger.app/v1alpha3
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Canary
    Name:                  sockshop
    UID:                   d4cbde0d-e378-11e9-aa18-424f651a3093
  Resource Version:        5607
  Self Link:               /apis/networking.istio.io/v1alpha3/namespaces/sock-shop/virtualservices/front-end
  UID:                     d5672ea8-e378-11e9-aa18-424f651a3093
Spec:
  Gateways:
    sockshop-gateway
  Hosts:
    sockshop.myexample.dev
    front-end
  Http:
    Route:
      Destination:
        Host:  front-end-primary
      Weight:  100
      Destination:
        Host:  front-end-canary
      Weight:  0
Events:        <none>
```

You can also see two new `DestinationRules`:

```bash
kubectl describe destinationrules.networking.istio.io -n sock-shop
```

Output:

```text
Name:         front-end-canary
Namespace:    sock-shop
Labels:       <none>
Annotations:  <none>
API Version:  networking.istio.io/v1alpha3
Kind:         DestinationRule
Metadata:
  Creation Timestamp:  2019-09-30T11:52:52Z
  Generation:          1
  Owner References:
    API Version:           flagger.app/v1alpha3
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Canary
    Name:                  sockshop
    UID:                   d4cbde0d-e378-11e9-aa18-424f651a3093
  Resource Version:        5597
  Self Link:               /apis/networking.istio.io/v1alpha3/namespaces/sock-shop/destinationrules/front-end-canary
  UID:                     d54c17cb-e378-11e9-aa18-424f651a3093
Spec:
  Host:  front-end-canary
Events:  <none>


Name:         front-end-primary
Namespace:    sock-shop
Labels:       <none>
Annotations:  <none>
API Version:  networking.istio.io/v1alpha3
Kind:         DestinationRule
Metadata:
  Creation Timestamp:  2019-09-30T11:52:52Z
  Generation:          1
  Owner References:
    API Version:           flagger.app/v1alpha3
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Canary
    Name:                  sockshop
    UID:                   d4cbde0d-e378-11e9-aa18-424f651a3093
  Resource Version:        5598
  Self Link:               /apis/networking.istio.io/v1alpha3/namespaces/sock-shop/destinationrules/front-end-primary
  UID:                     d556273d-e378-11e9-aa18-424f651a3093
Spec:
  Host:  front-end-primary
Events:  <none>
```

Modify the [https://github.com/ruzickap/front-end/edit/master/public/index.html](https://github.com/ruzickap/front-end/edit/master/public/index.html)
and replace "We love socks!" by "We really love socks!".

![GitHub edit](./github_edit.png "GitHub edit")

-----

Initiate build of a new container:

```bash
sed "s/podinfo-build-docker-image-from-git-pipelinerun/podinfo-build-docker-image-from-git-pipelinerun-2/" tmp/k8s-flux-repository/workloads/tekton-pipelinerun.yaml > tmp/k8s-flux-repository/workloads/tekton-pipelinerun-2.yaml
sed -i "s/0.3.12/0.4.0/" tmp/k8s-flux-repository/workloads/tekton-pipelineresource.yaml
git -C tmp/k8s-flux-repository diff
git -C tmp/k8s-flux-repository add --verbose .
git -C tmp/k8s-flux-repository commit -m "Start building the front-end container"
git -C tmp/k8s-flux-repository push -q
fluxctl sync
```

Open the Tekton Dashboard page [https://tekton-dashboard.myexample.dev](https://tekton-dashboard.myexample.dev)
to see the build process.

You should see a new PipelineRun:

![New PipelineRun](./tekton_dashboard.png "New PipelineRun")

Run tmux session with monitoring commands:

```bash
tmux new-session \; \
send-keys "\
  while true ; do
  fluxctl list-images -n sock-shop --workload sock-shop:deployment/front-end ;
  sleep 5 ;
  done
" C-m \; \
split-window -h -p 29 \; \
send-keys "while true; do kubectl get -n sock-shop canary/sockshop -o json | jq .status; sleep 2; done" C-m \; \
split-window -v -p 50 \; \
send-keys "while true; do kubectl -n sock-shop get canaries sockshop; sleep 3; done" C-m \; \
select-pane -t 0 \; \
split-window -v -p 50 \; \
send-keys "kubectl -n istio-system logs deployment/flagger -f | jq .msg" C-m \; \
split-window -h -p 16 \; \
send-keys "while true; do curl -sk https://sockshop.${MY_DOMAIN}/ | sed -n \"s@.*>\(We.*socks\!\)<.*@\1@p\"; sleep 2; done" C-m \; \
set-option status off
```

New version of Sockshop:

![New Sockshop](./new_sockshop.png "New Sockshop")
