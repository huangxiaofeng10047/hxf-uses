---
description: k3s 创建一主一从的集群
slug: k3s
public: true
title: k3s实践
createdAt: 1718872466238
updatedAt: 1718950106427
tags: []
heroImage: /posts/k3s_thumbnail.jpg
---
# Use JuiceFS on K3s

[K3s](https://k3s.io/) is a functionally optimized lightweight Kubernetes distribution that is fully compatible with Kubernetes.In other words, almost all operations performed on Kubernetes can also be executed on K3s. K3s packages the entire container orchestration system into a binary program with a size of less than 100MB, significantly reducing the environment dependencies and installation steps required to deploy Kubernetes production clusters. Compared to Kubernetes, K3s has lower performance requirements for the operating system.

In this article, we will build a K3s cluster with two nodes, install and configure [JuiceFS CSI Driver](https://github.com/juicedata/juicefs-csi-driver) for the cluster, and lastly create an NGINX Pod for verification.

## Deploy a K3s cluster[​](https://juicefs.com/docs/community/juicefs_on_k3s/#deploy-a-k3s-cluster "Direct link to heading")

K3s has very low **minimum requirements** for hardware:

- **Memory**: 512MB+ (recommend 1GB+)
- **CPU**: 1 core

When deploying a production cluster, it is recommended to start with a minimum hardware configuration of 4 cores and 8GB of memory per node. For more detailed information, please refer to the [Hardware Requirements](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#hardware) documentation.

### K3s server node[​](https://juicefs.com/docs/community/juicefs_on_k3s/#k3s-server-node "Direct link to heading")

The IP address of the server node is: `192.168.1.35`

You can use the official script provided by K3s to deploy the server node on a regular Linux distribution.

```shell
curl -sfL https://get.k3s.io | sh -
```

After the deployment is successful, the K3s service will automatically start, and kubectl and other tools will also be installed at the same time.

You can execute the following command to view the status of the node:

```shell
$ sudo kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
k3s-s1   Ready    control-plane,master   28h   v1.21.4+k3s1
```

Get the `node-token`:

```shell
sudo -u root cat /var/lib/rancher/k3s/server/node-token
```

### K3s worker node[​](https://juicefs.com/docs/community/juicefs_on_k3s/#k3s-worker-node "Direct link to heading")

The IP address of the worker node is: `192.168.1.36`

Execute the following command and change the value of `K3S_URL` to the IP or domain name of the server node (the default port is `6443`). Replace the value of `K3S_TOKEN` with the `node-token` obtained from the server node.

```shell
curl -sfL https://get.k3s.io | K3S_URL=http://192.168.1.35:6443 K3S_TOKEN=K1041f7c4fabcdefghijklmnopqrste2ec338b7300674f::server:3d0ab12800000000000000006328bbd80 sh -
```

After the deployment is successful, go back to the server node to check the node status:

```shell
xfhuang@ubuntu2:~$ sudo kubectl get nodes
NAME       STATUS   ROLES                  AGE     VERSION
ubuntu2    Ready    control-lane,master   7m33s   v1.29.5+k3s1
ubuntu-1   Ready    <none>                 80s     v1.29.5+k3s1
```

![thumb.png](/posts/k3s_thumb-png.png)
## Install CSI Driver[​](https://juicefs.com/docs/community/juicefs_on_k3s/#install-csi-driver "Direct link to heading")

It is consistent with the method of [Use JuiceFS on Kubernetes](https://juicefs.com/docs/community/how_to_use_on_kubernetes). Therefore, you can install CSI Driver through Helm or kubectl.

Here we use kubectl as an example. Execute the following command to install the CSI Driver:

```shell
kubectl apply -f https://raw.githubusercontent.com/juicedata/juicefs-csi-driver/master/deploy/k8s.yaml
```
![clipboard.png](/posts/k3s_clipboard-png.png)
### Create Storage Class[​](https://juicefs.com/docs/community/juicefs_on_k3s/#create-storage-class "Direct link to heading")

Copy and modify the following code to create a configuration file, for example: `juicefs-sc.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://juicefs.afyq4z.0001.use1.cache.amazonaws.com/3"
  storage: "s3"
  bucket: "https://juicefs-test.s3.us-east-1.amazonaws.com"
  access-key: "<your-access-key-id>"
  secret-key: "<your-access-key-secret>"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: juicefs-sc
provisioner: csi.juicefs.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
parameters:
  csi.storage.k8s.io/node-publish-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/node-publish-secret-namespace: kube-system
  csi.storage.k8s.io/provisioner-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system
```


接下来看看资源，毕竟是一个小集群
一个主节点 一个从节点，都是1g2核心
非常的小。


```
apiVersion: v1
kind: Secret
metadata:
  name: juicefs-sc-secret
  namespace: kube-system
type: Opaque
stringData:
  name: "test"
  metaurl: "redis://10.7.20.12:6379"
  storage: "s3"
  bucket: "http://10.7.20.12:9000"
  access-key: "c6VzVSfQvgspXBTW"
  secret-key: "QMY4kHz1y8l1xNEFLX7khVxgilYwuemL"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: juicefs-sc
provisioner: csi.juicefs.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
parameters:
  csi.storage.k8s.io/node-publish-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/node-publish-secret-namespace: kube-system
  csi.storage.k8s.io/provisioner-secret-name: juicefs-sc-secret
  csi.storage.k8s.io/provisioner-secret-namespace: kube-system

```

如何修改k3s的traefik需要注意一下几点
## Installing k3s

The k3s installation process is fairly straightforward. It just requires `curl`ing `https://get.k3s.io` and executing the script. The default settings all make sense to me, except for the need to `chmod` the bundled kubeconfig since its default filemode is inaccessible to non-root users. Luckly, k3s has a solution for that! All you need to do is `export K3S_KUBECONFIG_MODE="644"` before you run the installation, and the k3s install script does the rest.

## Configuring Traefik

By default, host ports 80 and 443 are exposed by the bundled Traefik ingress controller. This will let you create HTTP and HTTPS ingresses on their standard ports.

But of course, I want to run a [QuestDB](https://questdb.io/) instance on my node, which uses two additional TCP ports for Influx Line Protocol (ILP) and Pgwire communication with the database. So how can I expose these extra ports on my node and route traffic to the QuestDB container running inside of k3s?

K3s deploys Traefik via a Helm chart and allows you to modify that chart's `values.yaml` through a [HelmChartConfig](https://docs.k3s.io/helm#customizing-packaged-components-with-helmchartconfig) resource. To further customize `values.yaml` files for installed charts, you can place extra HelmChartConfig manifests in `/var/lib/rancher/k3s/server/manifests`. Here is my `/var/lib/rancher/k3s/server/manifests/traefik-config.yaml`:

```
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      psql:
        port: 8812
        expose: true
        exposedPort: 8812
        protocol: TCP
      ilp:
        port: 9009
        expose: true
        exposedPort: 9009
        protocol: TCP
```

This manifest modifies the Traefik deployment to serve two extra TCP ports on the host: 8812 for Pgwire and 9009 for ILP. Along with these new ports, Traefik also ships with its default "web" and "websecure" ports that route HTTP and HTTPS traffic respectively. But this is already preconfigured for you in the Helm chart, so there's no extra work involved.

So now that we have our ports exposed, lets figure out how to route traffic from them to our QuestDB instance running inside the cluster.

## IngressRoutes

While you can use traditional k8s [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/) to configure external access to cluster resources, Traefik v2 also includes new, more flexible types of ingress that coordinate directly with the Traefik deployment. These can be configured by using Traefik-specific Custom Resources, which allow users to specify cluster ingress routes using [Traefik's custom routing rules](https://doc.traefik.io/traefik/routing/routers/) instead of the standard URI-based routing traditionally found in k8s. Using these rules, you can route requests not just based on hostnames and paths, but also by request headers, querystrings, and source IPs, with regex matching support for many of these options. This unlocks significantly more flexibility when routing traffic into your cluster as opposed to using a standard k8s ingress.

Here's an example of an IngressRoute that I use to expose the QuestDB web console.

```
---
kind: IngressRoute
metadata:
  name: questdb
  namespace: questdb
spec:
  entryPoints:
    - web
  routes:
    - kind: Rule
      match: Host(`my-hostname`)
      services:
        - kind: Service
          name: questdb
          port: 9000
```

This CRD maps the QuestDB service port 9000 to host port 80 through the `web` entrypoint, which as I mentioned above, comes pre-installed in the Traefik Helm chart. With this config, I can now access the console by navigating to <http://my-hostname/> in my web browser and Traefik will route the request to my QuestDB HTTP service.

### IngressRouteTCP

It's important to note that IngressRoutes are used solely for HTTP ingress routing. Raw TCP routing is done using IngressRouteTCPs, and there are also IngressRouteUDPs available for you to use as well.

To support the TCP-based ILP and Pgwire protocols, I created 2 `IngressRouteTCP` resources to handle traffic on host ports 9009 and 8812.

```
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: questdb-ilp
  namespace: questdb
spec:
  entryPoints:
    - ilp
  routes:
    - match: HostSNI(`*`)
      services:
        - name: questdb
          port: 9009
          terminationDelay: -1
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: questdb-psql
  namespace: questdb
spec:
  entryPoints:
    - psql
  routes:
    - match: HostSNI(`*`)
      services:
        - name: questdb
          port: 8812
```

Here, we use the TCP-specific `HostSNI` matcher to route all node traffic on ports 9009 (`ilp`) and 8812 (`psql`) to the questdb service. The `ilp` and `psql` entrypoints correspond to the `ilp` and `psql` ports that we exposed in the `traefik-config.yaml`.

Now we're able to access QuestDB on all 3 supported ports on my k3s node from the rest of my home network.

## Conclusion

I hope this example gives you a bit more confidence when configuring Traefik on a single-node k3s "cluster". It may be a bit confusing at first, but once you have the basics down, you'll be exposing all of your hosted services in no time!

Since we're only working with one node, there's a limited amount of routing flexibility that I could include in the Traefik CRD configurations. In a more complex environment, you can really go wild with all of the possibilities that are provided by Traefik routing rules! Still, the benefit of this simple example is that you can learn the basics in a small and controlled environment, and then add complexity once it's needed.

Remember, if you're using k3s clustering mode and running multiple nodes, you'll need to route traffic using an [external load balancer](https://docs.k3s.io/datastore/cluster-loadbalancer) like Haproxy. Maybe I'll play around with this if I ever pick up a second M900 or other mini-desktop. But until then, I'll stick with this ingress configuration.
