---
description: k3s 创建一主一从的集群
slug: k3s
public: true
title: k3s实践
createdAt: 1718872466238
updatedAt: 1719215937655
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

部署traefik-dashboard
先看效果
![clipboard.png](/posts/k3s_clipboard-png.png)
来看看配置文件
## Expose traefik dashboard

You can use both Kubernetes standard Ingress or the Traefik CRD ingressroute for normal routes. To expose the dashboard you can use a traefik specific ingressroute CRD, or you can set up a service for it.

Create service

```
cat traefik-dashboard-service.yaml | envsubst | kubectl apply -f -
```

traefik-dashboard-service.yaml

```
```

Create ingress

```
cat traefik-dashboard-ingress.yaml | envsubst | kubectl apply -f -
```

traefik-dashboard-ingress.yaml

```
```

Now it should be available at http\://traefik.dog.example.com/dashboard/ (note the trailing slash!).

## Old method, using cert-manager

#### Create https certificate for ingressroute

Traefik does not support using cert-manager for tls. So when using ingressroute with https you need to first create a "fake" ingress to get a secret with the desired name. Then you use that secret like below.

> **Wildcard:** Alternatively you could get a wildcard certificate, and just use that. The setup for that is slightly more complicated and might require using a third party nameserver like digitalocean or cloudflare to help with the challenges.

- Create the temporary ingress so cert-manager gets the intial certificate

```
cat traefik-dashboard-tmp-ingress.yaml | envsubst | kubectl apply -f -
```

- Wait until you are able to access [https://traefik.dog.example.com](https://traefik.dog.example.com/) without errors or warnings about certificate.
- Then delete it

```
cat traefik-dashboard-tmp-ingress.yaml | envsubst | kubectl delete -f -
```

- Finally create the traefik native ingressroute

```
cat traefik-ingressroute-no-auth.yaml | envsubst | kubectl apply -f -
```

# Done

Now you should have the traefik dashboard available on [https://traefik.dog.yourdomain.com](https://traefik.dog.example.com/)

参考文档：

https://k3s.rocks/traefik-dashboard/

其实你 还以添加basicAuth来进行验证，这里没操作，留着下次操作

https://doc.traefik.io/traefik/middlewares/http/basicauth/

https://k3s.rocks/basic-auth/

安装helm

```
# Install K3S
curl -sfL https://get.k3s.io | sh -

# Copy k3s config
mkdir $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chmod 644 $HOME/.kube/config

# Check K3S 
kubectl get pods -n kube-system

# Create Storage class
# kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
# kubectl get storageclass

# Download & install Helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh
chmod u+x install-helm.sh
./install-helm.sh

# Link Helm with Tiller
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller

# Check Helm
helm repo update
helm search postgres

# Install NATS with Helm
# https://hub.helm.sh/charts/bitnami/nats
helm install --name nats --namespace demo \
	--set auth.enabled=true,auth.user=admin,auth.password=admin1234 \
	stable/nats
	
# Check
helm list
kubectl svc -n demo

# Create a port forward to NATS (blocking the terminal)
kubectl port-forward svc/nats-client 4222 -n demo

# Delete NATS
helm delete nats

# Working DNS with ufw  https://github.com/rancher/k3s/issues/24#issuecomment-515003702
# sudo ufw allow in on cni0 from 10.42.0.0/16 comment "K3s rule"
@huangxiaofeng10047
Comment


helm install my-release -f values-test.yaml oci://registry-1.docker.io/bitnamicharts/mysql

```

安装后可以看到如下：

```shell
root@ubuntu2:~# helm install my-release -f values-test.yaml oci://registry-1.docker.io/bitnamicharts/mysql
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /root/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /root/.kube/config
Pulled: registry-1.docker.io/bitnamicharts/mysql:11.1.4
Digest: sha256:d84741389d17c9bd96e4d885fb54fb4c21f9aeb546758c3107201b7fcf534555
NAME: my-release
LAST DEPLOYED: Mon Jun 24 01:43:34 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: mysql
CHART VERSION: 11.1.4
APP VERSION: 8.4.0

** Please be patient while the chart is being deployed **

Tip:

  Watch the deployment status using the command: kubectl get pods -w --namespace default

Services:

  echo Primary: my-release-mysql.default.svc.cluster.local:3306

Execute the following to get the administrator credentials:

  echo Username: root
  MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default my-release-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)

To connect to your database:

  1. Run a pod that you can use as a client:

      kubectl run my-release-mysql-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.34-debian-11-r31 --namespace default --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash

  2. To connect to primary service (read/write):

      mysql -h my-release-mysql.default.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"






⚠ SECURITY WARNING: Original containers have been substituted. This Helm chart was designed, tested, and validated on multiple platforms using a specific set of Bitnami and Tanzu Application Catalog containers. Substituting other containers is likely to cause degraded security and performance, broken chart features, and missing environment variables.

Substituted images detected:
  - docker.io/bitnami/mysql:8.0.34-debian-11-r31
  - docker.io/bitnami/os-shell:11-debian-11-r43
  - docker.io/bitnami/mysqld-exporter:0.15.0-debian-11-r24


```

更新

```

helm upgrade my-release -f values-test.yaml oci://registry-1.docker.io/bitnamicharts/mysql

```

values-test.yaml如下所示

```yaml
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

## @section Global parameters
## Global Docker image parameters
## Please, note that this will override the image parameters, including dependencies, configured to use the global value
## Current available global Docker image parameters: imageRegistry, imagePullSecrets and storageClass
##

## @param global.imageRegistry Global Docker image registry
## @param global.imagePullSecrets Global Docker registry secret names as an array
## @param global.storageClass Global StorageClass for Persistent Volume(s)
##
global:
  imageRegistry: ""
  ## E.g.
  ## imagePullSecrets:
  ##   - myRegistryKeySecretName
  ##
  imagePullSecrets: []
  storageClass: "juicefs-sc"  #juicefs-sc 是pvc
  ## Compatibility adaptations for Kubernetes platforms
  ##
  compatibility:
    ## Compatibility adaptations for Openshift
    ##
    openshift:
      ## @param global.compatibility.openshift.adaptSecurityContext Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC: remove runAsUser, runAsGroup and fsGroup and let the platform use their allowed default IDs. Possible values: auto (apply if the detected running cluster is Openshift), force (perform the adaptation always), disabled (do not perform adaptation)
      ##
      adaptSecurityContext: auto
## @section Common parameters
##

## @param kubeVersion Force target Kubernetes version (using Helm capabilities if not set)
##
kubeVersion: ""
## @param nameOverride String to partially override common.names.fullname template (will maintain the release name)
##
nameOverride: ""
## @param fullnameOverride String to fully override common.names.fullname template
##
fullnameOverride: ""
## @param namespaceOverride String to fully override common.names.namespace
##
namespaceOverride: ""
## @param clusterDomain Cluster domain
##
clusterDomain: cluster.local
## @param commonAnnotations Common annotations to add to all MySQL resources (sub-charts are not considered). Evaluated as a template
##
commonAnnotations: {}
## @param commonLabels Common labels to add to all MySQL resources (sub-charts are not considered). Evaluated as a template
##
commonLabels: {}
## @param extraDeploy Array with extra yaml to deploy with the chart. Evaluated as a template
##
extraDeploy: []
## @param serviceBindings.enabled Create secret for service binding (Experimental)
## Ref: https://servicebinding.io/service-provider/
##
serviceBindings:
  enabled: false
## Enable diagnostic mode in the deployment
##
diagnosticMode:
  ## @param diagnosticMode.enabled Enable diagnostic mode (all probes will be disabled and the command will be overridden)
  ##
  enabled: false
  ## @param diagnosticMode.command Command to override all containers in the deployment
  ##
  command:
    - sleep
  ## @param diagnosticMode.args Args to override all containers in the deployment
  ##
  args:
    - infinity
## @section MySQL common parameters
##

## Bitnami MySQL image
## ref: https://hub.docker.com/r/bitnami/mysql/tags/
## @param image.registry [default: REGISTRY_NAME] MySQL image registry
## @param image.repository [default: REPOSITORY_NAME/mysql] MySQL image repository
## @skip image.tag MySQL image tag (immutable tags are recommended)
## @param image.digest MySQL image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag
## @param image.pullPolicy MySQL image pull policy
## @param image.pullSecrets Specify docker-registry secret names as an array
## @param image.debug Specify if debug logs should be enabled
##
image:
  registry: docker.io
  repository: bitnami/mysql
  tag: 8.4.0-debian-12-r3
  digest: ""
  ## Specify a imagePullPolicy
  ## Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent'
  ## ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images
  ##
  pullPolicy: IfNotPresent
  ## Optionally specify an array of imagePullSecrets (secrets must be manually created in the namespace)
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ## Example:
  ## pullSecrets:
  ##   - myRegistryKeySecretName
  ##
  pullSecrets: []
  ## Set to true if you would like to see extra information on logs
  ## It turns BASH and/or NAMI debugging in the image
  ##
  debug: false
## @param architecture MySQL architecture (`standalone` or `replication`)
##
architecture: standalone
## MySQL Authentication parameters
##
auth:
  ## @param auth.rootPassword Password for the `root` user. Ignored if existing secret is provided
  ## ref: https://github.com/bitnami/containers/tree/main/bitnami/mysql#setting-the-root-password-on-first-run
  ##
  rootPassword: ""
  ## @param auth.createDatabase Whether to create the .Values.auth.database or not
  ## ref: https://github.com/bitnami/containers/tree/main/bitnami/mysql#creating-a-database-on-first-run
  ##
  createDatabase: true
  ## @param auth.database Name for a custom database to create
  ## ref: https://github.com/bitnami/containers/tree/main/bitnami/mysql#creating-a-database-on-first-run
  ##
  database: "my_database"
  ## @param auth.username Name for a custom user to create
  ## ref: https://github.com/bitnami/containers/tree/main/bitnami/mysql#creating-a-database-user-on-first-run
  ##
  username: ""
  ## @param auth.password Password for the new user. Ignored if existing secret is provided
  ##
  password: ""
  ## @param auth.replicationUser MySQL replication user
  ## ref: https://github.com/bitnami/containers/tree/main/bitnami/mysql#setting-up-a-replication-cluster
  ##
  replicationUser: replicator
  ## @param auth.replicationPassword MySQL replication user password. Ignored if existing secret is provided
  ##
  replicationPassword: ""
  ## @param auth.existingSecret Use existing secret for password details. The secret has to contain the keys `mysql-root-password`, `mysql-replication-password` and `mysql-password`
  ## NOTE: When it's set the auth.rootPassword, auth.password, auth.replicationPassword are ignored.
  ##
  existingSecret: ""
  ## @param auth.usePasswordFiles Mount credentials as files instead of using an environment variable
  ##
  usePasswordFiles: false
  ## @param auth.customPasswordFiles Use custom password files when `auth.usePasswordFiles` is set to `true`. Define path for keys `root` and `user`, also define `replicator` if `architecture` is set to `replication`
  ## Example:
  ## customPasswordFiles:
  ##   root: /vault/secrets/mysql-root
  ##   user: /vault/secrets/mysql-user
  ##   replicator: /vault/secrets/mysql-replicator
  ##
  customPasswordFiles: {}
  ## @param auth.authenticationPolicy Sets the authentication policy, by default it will use `* ,,`
  ## ref: https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html#sysvar_authentication_policy
  ##
  authenticationPolicy: ""
## @param initdbScripts Dictionary of initdb scripts
## Specify dictionary of scripts to be run at first boot
## Example:
## initdbScripts:
##   my_init_script.sh: |
##      #!/bin/bash
##      echo "Do something."
##
initdbScripts: {}
## @param initdbScriptsConfigMap ConfigMap with the initdb scripts (Note: Overrides `initdbScripts`)
##
initdbScriptsConfigMap: ""
## @param startdbScripts Dictionary of startdb scripts
## Specify dictionary of scripts to be run every time the container is started
## Example:
## startdbScripts:
##   my_start_script.sh: |
##      #!/bin/bash
##      echo "Do something."
##
startdbScripts: {}
## @param startdbScriptsConfigMap ConfigMap with the startdb scripts (Note: Overrides `startdbScripts`)
##
startdbScriptsConfigMap: ""
## @section MySQL Primary parameters
##
primary:
  ## @param primary.name Name of the primary database (eg primary, master, leader, ...)
  ##
  name: primary
  ## @param primary.command Override default container command on MySQL Primary container(s) (useful when using custom images)
  ##
  command: []
  ## @param primary.args Override default container args on MySQL Primary container(s) (useful when using custom images)
  ##
  args: []
  ## @param primary.lifecycleHooks for the MySQL Primary container(s) to automate configuration before or after startup
  ##
  lifecycleHooks: {}
  ## @param primary.automountServiceAccountToken Mount Service Account token in pod
  ##
  automountServiceAccountToken: false
  ## @param primary.hostAliases Deployment pod host aliases
  ## https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/
  ##
  hostAliases: []
  ## @param primary.enableMySQLX Enable mysqlx port
  ## ref: https://dev.mysql.com/doc/dev/mysql-server/latest/mysqlx_protocol_xplugin.html
  ##
  enableMySQLX: false
  ## @param primary.configuration [string] Configure MySQL Primary with a custom my.cnf file
  ## ref: https://mysql.com/kb/en/mysql/configuring-mysql-with-mycnf/#example-of-configuration-file
  ##
  configuration: |-
    [mysqld]
    authentication_policy='{{- .Values.auth.authenticationPolicy | default "* ,," }}'
    skip-name-resolve
    explicit_defaults_for_timestamp
    basedir=/opt/bitnami/mysql
    plugin_dir=/opt/bitnami/mysql/lib/plugin
    port={{ .Values.primary.containerPorts.mysql }}
    mysqlx={{ ternary 1 0 .Values.primary.enableMySQLX }}
    mysqlx_port={{ .Values.primary.containerPorts.mysqlx }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    datadir=/bitnami/mysql/data
    tmpdir=/opt/bitnami/mysql/tmp
    max_allowed_packet=16M
    bind-address=*
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
    log-error=/opt/bitnami/mysql/logs/mysqld.log
    character-set-server=UTF8
    slow_query_log=0
    long_query_time=10.0

    [client]
    port={{ .Values.primary.containerPorts.mysql }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    default-character-set=UTF8
    plugin_dir=/opt/bitnami/mysql/lib/plugin

    [manager]
    port={{ .Values.primary.containerPorts.mysql }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
  ## @param primary.existingConfigmap Name of existing ConfigMap with MySQL Primary configuration.
  ## NOTE: When it's set the 'configuration' parameter is ignored
  ##
  existingConfigmap: ""
  ## @param primary.containerPorts.mysql Container port for mysql
  ## @param primary.containerPorts.mysqlx Container port for mysqlx
  ##
  containerPorts:
    mysql: 3306
    mysqlx: 33060
  ## @param primary.updateStrategy.type Update strategy type for the MySQL primary statefulset
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies
  ##
  updateStrategy:
    type: RollingUpdate
  ## @param primary.podAnnotations Additional pod annotations for MySQL primary pods
  ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/
  ##
  podAnnotations: {}
  ## @param primary.podAffinityPreset MySQL primary pod affinity preset. Ignored if `primary.affinity` is set. Allowed values: `soft` or `hard`
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity
  ##
  podAffinityPreset: ""
  ## @param primary.podAntiAffinityPreset MySQL primary pod anti-affinity preset. Ignored if `primary.affinity` is set. Allowed values: `soft` or `hard`
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity
  ##
  podAntiAffinityPreset: soft
  ## MySQL Primary node affinity preset
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity
  ##
  nodeAffinityPreset:
    ## @param primary.nodeAffinityPreset.type MySQL primary node affinity preset type. Ignored if `primary.affinity` is set. Allowed values: `soft` or `hard`
    ##
    type: ""
    ## @param primary.nodeAffinityPreset.key MySQL primary node label key to match Ignored if `primary.affinity` is set.
    ## E.g.
    ## key: "kubernetes.io/e2e-az-name"
    ##
    key: ""
    ## @param primary.nodeAffinityPreset.values MySQL primary node label values to match. Ignored if `primary.affinity` is set.
    ## E.g.
    ## values:
    ##   - e2e-az1
    ##   - e2e-az2
    ##
    values: []
  ## @param primary.affinity Affinity for MySQL primary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
  ## Note: podAffinityPreset, podAntiAffinityPreset, and  nodeAffinityPreset will be ignored when it's set
  ##
  affinity: {}
  ## @param primary.nodeSelector Node labels for MySQL primary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
  ##
  nodeSelector: {}
  ## @param primary.tolerations Tolerations for MySQL primary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  ##
  tolerations: []
  ## @param primary.priorityClassName MySQL primary pods' priorityClassName
  ##
  priorityClassName: ""
  ## @param primary.runtimeClassName MySQL primary pods' runtimeClassName
  ##
  runtimeClassName: ""
  ## @param primary.schedulerName Name of the k8s scheduler (other than default)
  ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
  ##
  schedulerName: ""
  ## @param primary.terminationGracePeriodSeconds In seconds, time the given to the MySQL primary pod needs to terminate gracefully
  ## ref: https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods
  ##
  terminationGracePeriodSeconds: ""
  ## @param primary.topologySpreadConstraints Topology Spread Constraints for pod assignment
  ## https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  ## The value is evaluated as a template
  ##
  topologySpreadConstraints: []
  ## @param primary.podManagementPolicy podManagementPolicy to manage scaling operation of MySQL primary pods
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#pod-management-policies
  ##
  podManagementPolicy: ""
  ## MySQL primary Pod security context
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod
  ## @param primary.podSecurityContext.enabled Enable security context for MySQL primary pods
  ## @param primary.podSecurityContext.fsGroupChangePolicy Set filesystem group change policy
  ## @param primary.podSecurityContext.sysctls Set kernel settings using the sysctl interface
  ## @param primary.podSecurityContext.supplementalGroups Set filesystem extra groups
  ## @param primary.podSecurityContext.fsGroup Group ID for the mounted volumes' filesystem
  ##
  podSecurityContext:
    enabled: true
    fsGroupChangePolicy: Always
    sysctls: []
    supplementalGroups: []
    fsGroup: 1001
  ## MySQL primary container security context
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container
  ## @param primary.containerSecurityContext.enabled MySQL primary container securityContext
  ## @param primary.containerSecurityContext.seLinuxOptions [object,nullable] Set SELinux options in container
  ## @param primary.containerSecurityContext.runAsUser User ID for the MySQL primary container
  ## @param primary.containerSecurityContext.runAsGroup Group ID for the MySQL primary container
  ## @param primary.containerSecurityContext.runAsNonRoot Set MySQL primary container's Security Context runAsNonRoot
  ## @param primary.containerSecurityContext.allowPrivilegeEscalation Set container's privilege escalation
  ## @param primary.containerSecurityContext.capabilities.drop Set container's Security Context runAsNonRoot
  ## @param primary.containerSecurityContext.seccompProfile.type Set Client container's Security Context seccomp profile
  ## @param primary.containerSecurityContext.readOnlyRootFilesystem Set container's Security Context read-only root filesystem
  ##
  containerSecurityContext:
    enabled: true
    seLinuxOptions: {}
    runAsUser: 1001
    runAsGroup: 1001
    runAsNonRoot: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
    seccompProfile:
      type: "RuntimeDefault"
    readOnlyRootFilesystem: true
  ## MySQL primary container's resource requests and limits
  ## ref: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
  ## We usually recommend not to specify default resources and to leave this as a conscious
  ## choice for the user. This also increases chances charts run on environments with little
  ## resources, such as Minikube. If you do want to specify resources, uncomment the following
  ## lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  ## @param primary.resourcesPreset Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if primary.resources is set (primary.resources is recommended for production).
  ## More information: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15
  ##
  resourcesPreset: "small"
  ## @param primary.resources Set container requests and limits for different resources like CPU or memory (essential for production workloads)
  ## Example:
  ## resources:
  ##   requests:
  ##     cpu: 2
  ##     memory: 512Mi
  ##   limits:
  ##     cpu: 3
  ##     memory: 1024Mi
  ##
  resources: {}
  ## Configure extra options for liveness probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param primary.livenessProbe.enabled Enable livenessProbe
  ## @param primary.livenessProbe.initialDelaySeconds Initial delay seconds for livenessProbe
  ## @param primary.livenessProbe.periodSeconds Period seconds for livenessProbe
  ## @param primary.livenessProbe.timeoutSeconds Timeout seconds for livenessProbe
  ## @param primary.livenessProbe.failureThreshold Failure threshold for livenessProbe
  ## @param primary.livenessProbe.successThreshold Success threshold for livenessProbe
  ##
  livenessProbe:
    enabled: true
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  ## Configure extra options for readiness probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param primary.readinessProbe.enabled Enable readinessProbe
  ## @param primary.readinessProbe.initialDelaySeconds Initial delay seconds for readinessProbe
  ## @param primary.readinessProbe.periodSeconds Period seconds for readinessProbe
  ## @param primary.readinessProbe.timeoutSeconds Timeout seconds for readinessProbe
  ## @param primary.readinessProbe.failureThreshold Failure threshold for readinessProbe
  ## @param primary.readinessProbe.successThreshold Success threshold for readinessProbe
  ##
  readinessProbe:
    enabled: true
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  ## Configure extra options for startupProbe probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param primary.startupProbe.enabled Enable startupProbe
  ## @param primary.startupProbe.initialDelaySeconds Initial delay seconds for startupProbe
  ## @param primary.startupProbe.periodSeconds Period seconds for startupProbe
  ## @param primary.startupProbe.timeoutSeconds Timeout seconds for startupProbe
  ## @param primary.startupProbe.failureThreshold Failure threshold for startupProbe
  ## @param primary.startupProbe.successThreshold Success threshold for startupProbe
  ##
  startupProbe:
    enabled: true
    initialDelaySeconds: 15
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 10
    successThreshold: 1
  ## @param primary.customLivenessProbe Override default liveness probe for MySQL primary containers
  ##
  customLivenessProbe: {}
  ## @param primary.customReadinessProbe Override default readiness probe for MySQL primary containers
  ##
  customReadinessProbe: {}
  ## @param primary.customStartupProbe Override default startup probe for MySQL primary containers
  ##
  customStartupProbe: {}
  ## @param primary.extraFlags MySQL primary additional command line flags
  ## Can be used to specify command line flags, for example:
  ## E.g.
  ## extraFlags: "--max-connect-errors=1000 --max_connections=155"
  ##
  extraFlags: ""
  ## @param primary.extraEnvVars Extra environment variables to be set on MySQL primary containers
  ## E.g.
  ## extraEnvVars:
  ##  - name: TZ
  ##    value: "Europe/Paris"
  ##
  extraEnvVars: []
  ## @param primary.extraEnvVarsCM Name of existing ConfigMap containing extra env vars for MySQL primary containers
  ##
  extraEnvVarsCM: ""
  ## @param primary.extraEnvVarsSecret Name of existing Secret containing extra env vars for MySQL primary containers
  ##
  extraEnvVarsSecret: ""
  ## @param primary.extraPodSpec Optionally specify extra PodSpec for the MySQL Primary pod(s)
  ##
  extraPodSpec: {}
  ## @param primary.extraPorts Extra ports to expose
  ##
  extraPorts: []
  ## Enable persistence using Persistent Volume Claims
  ## ref: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
  ##
  persistence:
    ## @param primary.persistence.enabled Enable persistence on MySQL primary replicas using a `PersistentVolumeClaim`. If false, use emptyDir
    ##
    enabled: true
    ## @param primary.persistence.existingClaim Name of an existing `PersistentVolumeClaim` for MySQL primary replicas
    ## NOTE: When it's set the rest of persistence parameters are ignored
    ##
    existingClaim: ""
    ## @param primary.persistence.subPath The name of a volume's sub path to mount for persistence
    ##
    subPath: ""
    ## @param primary.persistence.storageClass MySQL primary persistent volume storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    storageClass: ""
    ## @param primary.persistence.annotations MySQL primary persistent volume claim annotations
    ##
    annotations: {}
    ## @param primary.persistence.accessModes MySQL primary persistent volume access Modes
    ##
    accessModes:
      - ReadWriteOnce
    ## @param primary.persistence.size MySQL primary persistent volume size
    ##
    size: 8Gi
    ## @param primary.persistence.selector Selector to match an existing Persistent Volume
    ## selector:
    ##   matchLabels:
    ##     app: my-app
    ##
    selector: {}
  ## Primary Persistent Volume Claim Retention Policy
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention
  ##
  persistentVolumeClaimRetentionPolicy:
    ## @param primary.persistentVolumeClaimRetentionPolicy.enabled Enable Persistent volume retention policy for Primary StatefulSet
    ##
    enabled: false
    ## @param primary.persistentVolumeClaimRetentionPolicy.whenScaled Volume retention behavior when the replica count of the StatefulSet is reduced
    ##
    whenScaled: Retain
    ## @param primary.persistentVolumeClaimRetentionPolicy.whenDeleted Volume retention behavior that applies when the StatefulSet is deleted
    ##
    whenDeleted: Retain
  ## @param primary.extraVolumes Optionally specify extra list of additional volumes to the MySQL Primary pod(s)
  ##
  extraVolumes: []
  ## @param primary.extraVolumeMounts Optionally specify extra list of additional volumeMounts for the MySQL Primary container(s)
  ##
  extraVolumeMounts: []
  ## @param primary.initContainers Add additional init containers for the MySQL Primary pod(s)
  ##
  initContainers: []
  ## @param primary.sidecars Add additional sidecar containers for the MySQL Primary pod(s)
  ##
  sidecars: []
  ## MySQL Primary Service parameters
  ##
  service:
    ## @param primary.service.type MySQL Primary K8s service type
    ##
    type: ClusterIP
    ## @param primary.service.ports.mysql MySQL Primary K8s service port
    ## @param primary.service.ports.mysqlx MySQL Primary K8s service mysqlx port
    ##
    ports:
      mysql: 3306
      mysqlx: 33060
    ## @param primary.service.nodePorts.mysql MySQL Primary K8s service node port
    ## @param primary.service.nodePorts.mysqlx MySQL Primary K8s service node port mysqlx
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
    ##
    nodePorts:
      mysql: ""
      mysqlx: ""
    ## @param primary.service.clusterIP MySQL Primary K8s service clusterIP IP
    ## e.g:
    ## clusterIP: None
    ##
    clusterIP: ""
    ## @param primary.service.loadBalancerIP MySQL Primary loadBalancerIP if service type is `LoadBalancer`
    ## Set the LoadBalancer service type to internal only
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer
    ##
    loadBalancerIP: ""
    ## @param primary.service.externalTrafficPolicy Enable client source IP preservation
    ## ref https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip
    ##
    externalTrafficPolicy: Cluster
    ## @param primary.service.loadBalancerSourceRanges Addresses that are allowed when MySQL Primary service is LoadBalancer
    ## https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/#restrict-access-for-loadbalancer-service
    ## E.g.
    ## loadBalancerSourceRanges:
    ##   - 10.10.10.0/24
    ##
    loadBalancerSourceRanges: []
    ## @param primary.service.extraPorts Extra ports to expose (normally used with the `sidecar` value)
    ##
    extraPorts: []
    ## @param primary.service.annotations Additional custom annotations for MySQL primary service
    ##
    annotations: {}
    ## @param primary.service.sessionAffinity Session Affinity for Kubernetes service, can be "None" or "ClientIP"
    ## If "ClientIP", consecutive client requests will be directed to the same Pod
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies
    ##
    sessionAffinity: None
    ## @param primary.service.sessionAffinityConfig Additional settings for the sessionAffinity
    ## sessionAffinityConfig:
    ##   clientIP:
    ##     timeoutSeconds: 300
    ##
    sessionAffinityConfig: {}
    ## Headless service properties
    ##
    headless:
      ## @param primary.service.headless.annotations Additional custom annotations for headless MySQL primary service.
      ##
      annotations: {}
  ## MySQL primary Pod Disruption Budget configuration
  ## ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
  ##
  pdb:
    ## @param primary.pdb.create Enable/disable a Pod Disruption Budget creation for MySQL primary pods
    ##
    create: true
    ## @param primary.pdb.minAvailable Minimum number/percentage of MySQL primary pods that should remain scheduled
    ##
    minAvailable: ""
    ## @param primary.pdb.maxUnavailable Maximum number/percentage of MySQL primary pods that may be made unavailable. Defaults to `1` if both `primary.pdb.minAvailable` and `primary.pdb.maxUnavailable` are empty.
    ##
    maxUnavailable: ""
  ## @param primary.podLabels MySQL Primary pod label. If labels are same as commonLabels , this will take precedence
  ##
  podLabels: {}
## @section MySQL Secondary parameters
##
secondary:
  ## @param secondary.name Name of the secondary database (eg secondary, slave, ...)
  ##
  name: secondary
  ## @param secondary.replicaCount Number of MySQL secondary replicas
  ##
  replicaCount: 1
  ## @param secondary.automountServiceAccountToken Mount Service Account token in pod
  ##
  automountServiceAccountToken: false
  ## @param secondary.hostAliases Deployment pod host aliases
  ## https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/
  ##
  hostAliases: []
  ## @param secondary.command Override default container command on MySQL Secondary container(s) (useful when using custom images)
  ##
  command: []
  ## @param secondary.args Override default container args on MySQL Secondary container(s) (useful when using custom images)
  ##
  args: []
  ## @param secondary.lifecycleHooks for the MySQL Secondary container(s) to automate configuration before or after startup
  ##
  lifecycleHooks: {}
  ## @param secondary.enableMySQLX Enable mysqlx port
  ## ref: https://dev.mysql.com/doc/dev/mysql-server/latest/mysqlx_protocol_xplugin.html
  ##
  enableMySQLX: false
  ## @param secondary.configuration [string] Configure MySQL Secondary with a custom my.cnf file
  ## ref: https://mysql.com/kb/en/mysql/configuring-mysql-with-mycnf/#example-of-configuration-file
  ##
  configuration: |-
    [mysqld]
    authentication_policy='{{- .Values.auth.authenticationPolicy | default "* ,," }}'
    skip-name-resolve
    explicit_defaults_for_timestamp
    basedir=/opt/bitnami/mysql
    plugin_dir=/opt/bitnami/mysql/lib/plugin
    port={{ .Values.secondary.containerPorts.mysql }}
    mysqlx={{ ternary 1 0 .Values.secondary.enableMySQLX }}
    mysqlx_port={{ .Values.secondary.containerPorts.mysqlx }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    datadir=/bitnami/mysql/data
    tmpdir=/opt/bitnami/mysql/tmp
    max_allowed_packet=16M
    bind-address=*
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
    log-error=/opt/bitnami/mysql/logs/mysqld.log
    character-set-server=UTF8
    slow_query_log=0
    long_query_time=10.0

    [client]
    port={{ .Values.secondary.containerPorts.mysql }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    default-character-set=UTF8
    plugin_dir=/opt/bitnami/mysql/lib/plugin

    [manager]
    port={{ .Values.secondary.containerPorts.mysql }}
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
  ## @param secondary.existingConfigmap Name of existing ConfigMap with MySQL Secondary configuration.
  ## NOTE: When it's set the 'configuration' parameter is ignored
  ##
  existingConfigmap: ""
  ## @param secondary.containerPorts.mysql Container port for mysql
  ## @param secondary.containerPorts.mysqlx Container port for mysqlx
  ##
  containerPorts:
    mysql: 3306
    mysqlx: 33060
  ## @param secondary.updateStrategy.type Update strategy type for the MySQL secondary statefulset
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies
  ##
  updateStrategy:
    type: RollingUpdate
  ## @param secondary.podAnnotations Additional pod annotations for MySQL secondary pods
  ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/
  ##
  podAnnotations: {}
  ## @param secondary.podAffinityPreset MySQL secondary pod affinity preset. Ignored if `secondary.affinity` is set. Allowed values: `soft` or `hard`
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity
  ##
  podAffinityPreset: ""
  ## @param secondary.podAntiAffinityPreset MySQL secondary pod anti-affinity preset. Ignored if `secondary.affinity` is set. Allowed values: `soft` or `hard`
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity
  ## Allowed values: soft, hard
  ##
  podAntiAffinityPreset: soft
  ## MySQL Secondary node affinity preset
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity
  ##
  nodeAffinityPreset:
    ## @param secondary.nodeAffinityPreset.type MySQL secondary node affinity preset type. Ignored if `secondary.affinity` is set. Allowed values: `soft` or `hard`
    ##
    type: ""
    ## @param secondary.nodeAffinityPreset.key MySQL secondary node label key to match Ignored if `secondary.affinity` is set.
    ## E.g.
    ## key: "kubernetes.io/e2e-az-name"
    ##
    key: ""
    ## @param secondary.nodeAffinityPreset.values MySQL secondary node label values to match. Ignored if `secondary.affinity` is set.
    ## E.g.
    ## values:
    ##   - e2e-az1
    ##   - e2e-az2
    ##
    values: []
  ## @param secondary.affinity Affinity for MySQL secondary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
  ## Note: podAffinityPreset, podAntiAffinityPreset, and  nodeAffinityPreset will be ignored when it's set
  ##
  affinity: {}
  ## @param secondary.nodeSelector Node labels for MySQL secondary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
  ##
  nodeSelector: {}
  ## @param secondary.tolerations Tolerations for MySQL secondary pods assignment
  ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  ##
  tolerations: []
  ## @param secondary.priorityClassName MySQL secondary pods' priorityClassName
  ##
  priorityClassName: ""
  ## @param secondary.runtimeClassName MySQL secondary pods' runtimeClassName
  ##
  runtimeClassName: ""
  ## @param secondary.schedulerName Name of the k8s scheduler (other than default)
  ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
  ##
  schedulerName: ""
  ## @param secondary.terminationGracePeriodSeconds In seconds, time the given to the MySQL secondary pod needs to terminate gracefully
  ## ref: https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods
  ##
  terminationGracePeriodSeconds: ""
  ## @param secondary.topologySpreadConstraints Topology Spread Constraints for pod assignment
  ## https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  ## The value is evaluated as a template
  ##
  topologySpreadConstraints: []
  ## @param secondary.podManagementPolicy podManagementPolicy to manage scaling operation of MySQL secondary pods
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#pod-management-policies
  ##
  podManagementPolicy: ""
  ## MySQL secondary Pod security context
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod
  ## @param secondary.podSecurityContext.enabled Enable security context for MySQL secondary pods
  ## @param secondary.podSecurityContext.fsGroupChangePolicy Set filesystem group change policy
  ## @param secondary.podSecurityContext.sysctls Set kernel settings using the sysctl interface
  ## @param secondary.podSecurityContext.supplementalGroups Set filesystem extra groups
  ## @param secondary.podSecurityContext.fsGroup Group ID for the mounted volumes' filesystem
  ##
  podSecurityContext:
    enabled: true
    fsGroupChangePolicy: Always
    sysctls: []
    supplementalGroups: []
    fsGroup: 1001
  ## MySQL secondary container security context
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container
  ## @param secondary.containerSecurityContext.enabled MySQL secondary container securityContext
  ## @param secondary.containerSecurityContext.seLinuxOptions [object,nullable] Set SELinux options in container
  ## @param secondary.containerSecurityContext.runAsUser User ID for the MySQL secondary container
  ## @param secondary.containerSecurityContext.runAsGroup Group ID for the MySQL secondary container
  ## @param secondary.containerSecurityContext.runAsNonRoot Set MySQL secondary container's Security Context runAsNonRoot
  ## @param secondary.containerSecurityContext.allowPrivilegeEscalation Set container's privilege escalation
  ## @param secondary.containerSecurityContext.capabilities.drop Set container's Security Context runAsNonRoot
  ## @param secondary.containerSecurityContext.seccompProfile.type Set container's Security Context seccomp profile
  ## @param secondary.containerSecurityContext.readOnlyRootFilesystem Set container's Security Context read-only root filesystem
  ##
  containerSecurityContext:
    enabled: true
    seLinuxOptions: {}
    runAsUser: 1001
    runAsGroup: 1001
    runAsNonRoot: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
    seccompProfile:
      type: "RuntimeDefault"
    readOnlyRootFilesystem: true
  ## MySQL secondary container's resource requests and limits
  ## ref: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
  ## We usually recommend not to specify default resources and to leave this as a conscious
  ## choice for the user. This also increases chances charts run on environments with little
  ## resources, such as Minikube. If you do want to specify resources, uncomment the following
  ## lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  ## @param secondary.resourcesPreset Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if secondary.resources is set (secondary.resources is recommended for production).
  ## More information: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15
  ##
  resourcesPreset: "small"
  ## @param secondary.resources Set container requests and limits for different resources like CPU or memory (essential for production workloads)
  ## Example:
  ## resources:
  ##   requests:
  ##     cpu: 2
  ##     memory: 512Mi
  ##   limits:
  ##     cpu: 3
  ##     memory: 1024Mi
  ##
  resources: {}
  ## Configure extra options for liveness probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param secondary.livenessProbe.enabled Enable livenessProbe
  ## @param secondary.livenessProbe.initialDelaySeconds Initial delay seconds for livenessProbe
  ## @param secondary.livenessProbe.periodSeconds Period seconds for livenessProbe
  ## @param secondary.livenessProbe.timeoutSeconds Timeout seconds for livenessProbe
  ## @param secondary.livenessProbe.failureThreshold Failure threshold for livenessProbe
  ## @param secondary.livenessProbe.successThreshold Success threshold for livenessProbe
  ##
  livenessProbe:
    enabled: true
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  ## Configure extra options for readiness probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param secondary.readinessProbe.enabled Enable readinessProbe
  ## @param secondary.readinessProbe.initialDelaySeconds Initial delay seconds for readinessProbe
  ## @param secondary.readinessProbe.periodSeconds Period seconds for readinessProbe
  ## @param secondary.readinessProbe.timeoutSeconds Timeout seconds for readinessProbe
  ## @param secondary.readinessProbe.failureThreshold Failure threshold for readinessProbe
  ## @param secondary.readinessProbe.successThreshold Success threshold for readinessProbe
  ##
  readinessProbe:
    enabled: true
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 3
    successThreshold: 1
  ## Configure extra options for startupProbe probe
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#configure-probes
  ## @param secondary.startupProbe.enabled Enable startupProbe
  ## @param secondary.startupProbe.initialDelaySeconds Initial delay seconds for startupProbe
  ## @param secondary.startupProbe.periodSeconds Period seconds for startupProbe
  ## @param secondary.startupProbe.timeoutSeconds Timeout seconds for startupProbe
  ## @param secondary.startupProbe.failureThreshold Failure threshold for startupProbe
  ## @param secondary.startupProbe.successThreshold Success threshold for startupProbe
  ##
  startupProbe:
    enabled: true
    initialDelaySeconds: 15
    periodSeconds: 10
    timeoutSeconds: 1
    failureThreshold: 15
    successThreshold: 1
  ## @param secondary.customLivenessProbe Override default liveness probe for MySQL secondary containers
  ##
  customLivenessProbe: {}
  ## @param secondary.customReadinessProbe Override default readiness probe for MySQL secondary containers
  ##
  customReadinessProbe: {}
  ## @param secondary.customStartupProbe Override default startup probe for MySQL secondary containers
  ##
  customStartupProbe: {}
  ## @param secondary.extraFlags MySQL secondary additional command line flags
  ## Can be used to specify command line flags, for example:
  ## E.g.
  ## extraFlags: "--max-connect-errors=1000 --max_connections=155"
  ##
  extraFlags: ""
  ## @param secondary.extraEnvVars An array to add extra environment variables on MySQL secondary containers
  ## E.g.
  ## extraEnvVars:
  ##  - name: TZ
  ##    value: "Europe/Paris"
  ##
  extraEnvVars: []
  ## @param secondary.extraEnvVarsCM Name of existing ConfigMap containing extra env vars for MySQL secondary containers
  ##
  extraEnvVarsCM: ""
  ## @param secondary.extraEnvVarsSecret Name of existing Secret containing extra env vars for MySQL secondary containers
  ##
  extraEnvVarsSecret: ""
  ## @param secondary.extraPodSpec Optionally specify extra PodSpec for the MySQL Secondary pod(s)
  ##
  extraPodSpec: {}
  ## @param secondary.extraPorts Extra ports to expose
  ##
  extraPorts: []
  ## Enable persistence using Persistent Volume Claims
  ## ref: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
  ##
  persistence:
    ## @param secondary.persistence.enabled Enable persistence on MySQL secondary replicas using a `PersistentVolumeClaim`
    ##
    enabled: true
    ## @param secondary.persistence.existingClaim Name of an existing `PersistentVolumeClaim` for MySQL secondary replicas
    ## NOTE: When it's set the rest of persistence parameters are ignored
    ##
    existingClaim: ""
    ## @param secondary.persistence.subPath The name of a volume's sub path to mount for persistence
    ##
    subPath: ""
    ## @param secondary.persistence.storageClass MySQL secondary persistent volume storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    storageClass: ""
    ## @param secondary.persistence.annotations MySQL secondary persistent volume claim annotations
    ##
    annotations: {}
    ## @param secondary.persistence.accessModes MySQL secondary persistent volume access Modes
    ##
    accessModes:
      - ReadWriteOnce
    ## @param secondary.persistence.size MySQL secondary persistent volume size
    ##
    size: 8Gi
    ## @param secondary.persistence.selector Selector to match an existing Persistent Volume
    ## selector:
    ##   matchLabels:
    ##     app: my-app
    ##
    selector: {}
  ## Secondary Persistent Volume Claim Retention Policy
  ## ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention
  ##
  persistentVolumeClaimRetentionPolicy:
    ## @param secondary.persistentVolumeClaimRetentionPolicy.enabled Enable Persistent volume retention policy for read only StatefulSet
    ##
    enabled: false
    ## @param secondary.persistentVolumeClaimRetentionPolicy.whenScaled Volume retention behavior when the replica count of the StatefulSet is reduced
    ##
    whenScaled: Retain
    ## @param secondary.persistentVolumeClaimRetentionPolicy.whenDeleted Volume retention behavior that applies when the StatefulSet is deleted
    ##
    whenDeleted: Retain
  ## @param secondary.extraVolumes Optionally specify extra list of additional volumes to the MySQL secondary pod(s)
  ##
  extraVolumes: []
  ## @param secondary.extraVolumeMounts Optionally specify extra list of additional volumeMounts for the MySQL secondary container(s)
  ##
  extraVolumeMounts: []
  ## @param secondary.initContainers Add additional init containers for the MySQL secondary pod(s)
  ##
  initContainers: []
  ## @param secondary.sidecars Add additional sidecar containers for the MySQL secondary pod(s)
  ##
  sidecars: []
  ## MySQL Secondary Service parameters
  ##
  service:
    ## @param secondary.service.type MySQL secondary Kubernetes service type
    ##
    type: ClusterIP
    ## @param secondary.service.ports.mysql MySQL secondary Kubernetes service port
    ## @param secondary.service.ports.mysqlx MySQL secondary Kubernetes service port mysqlx
    ##
    ports:
      mysql: 3306
      mysqlx: 33060
    ## @param secondary.service.nodePorts.mysql MySQL secondary Kubernetes service node port
    ## @param secondary.service.nodePorts.mysqlx MySQL secondary Kubernetes service node port mysqlx
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
    ##
    nodePorts:
      mysql: ""
      mysqlx: ""
    ## @param secondary.service.clusterIP MySQL secondary Kubernetes service clusterIP IP
    ## e.g:
    ## clusterIP: None
    ##
    clusterIP: ""
    ## @param secondary.service.loadBalancerIP MySQL secondary loadBalancerIP if service type is `LoadBalancer`
    ## Set the LoadBalancer service type to internal only
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer
    ##
    loadBalancerIP: ""
    ## @param secondary.service.externalTrafficPolicy Enable client source IP preservation
    ## ref https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip
    ##
    externalTrafficPolicy: Cluster
    ## @param secondary.service.loadBalancerSourceRanges Addresses that are allowed when MySQL secondary service is LoadBalancer
    ## https://kubernetes.io/docs/tasks/access-application-cluster/configure-cloud-provider-firewall/#restrict-access-for-loadbalancer-service
    ## E.g.
    ## loadBalancerSourceRanges:
    ##   - 10.10.10.0/24
    ##
    loadBalancerSourceRanges: []
    ## @param secondary.service.extraPorts Extra ports to expose (normally used with the `sidecar` value)
    ##
    extraPorts: []
    ## @param secondary.service.annotations Additional custom annotations for MySQL secondary service
    ##
    annotations: {}
    ## @param secondary.service.sessionAffinity Session Affinity for Kubernetes service, can be "None" or "ClientIP"
    ## If "ClientIP", consecutive client requests will be directed to the same Pod
    ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies
    ##
    sessionAffinity: None
    ## @param secondary.service.sessionAffinityConfig Additional settings for the sessionAffinity
    ## sessionAffinityConfig:
    ##   clientIP:
    ##     timeoutSeconds: 300
    ##
    sessionAffinityConfig: {}
    ## Headless service properties
    ##
    headless:
      ## @param secondary.service.headless.annotations Additional custom annotations for headless MySQL secondary service.
      ##
      annotations: {}
  ## MySQL secondary Pod Disruption Budget configuration
  ## ref: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
  ##
  pdb:
    ## @param secondary.pdb.create Enable/disable a Pod Disruption Budget creation for MySQL secondary pods
    ##
    create: true
    ## @param secondary.pdb.minAvailable Minimum number/percentage of MySQL secondary pods that should remain scheduled
    ##
    minAvailable: ""
    ## @param secondary.pdb.maxUnavailable Maximum number/percentage of MySQL secondary pods that may be made unavailable. Defaults to `1` if both `secondary.pdb.minAvailable` and `secondary.pdb.maxUnavailable` are empty.
    ##
    maxUnavailable: ""
  ## @param secondary.podLabels Additional pod labels for MySQL secondary pods
  ##
  podLabels: {}
## @section RBAC parameters
##

## MySQL pods ServiceAccount
## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
##
serviceAccount:
  ## @param serviceAccount.create Enable the creation of a ServiceAccount for MySQL pods
  ##
  create: true
  ## @param serviceAccount.name Name of the created ServiceAccount
  ## If not set and create is true, a name is generated using the mysql.fullname template
  ##
  name: ""
  ## @param serviceAccount.annotations Annotations for MySQL Service Account
  ##
  annotations: {}
  ## @param serviceAccount.automountServiceAccountToken Automount service account token for the server service account
  ##
  automountServiceAccountToken: false
## Role Based Access
## ref: https://kubernetes.io/docs/admin/authorization/rbac/
##
rbac:
  ## @param rbac.create Whether to create & use RBAC resources or not
  ##
  create: false
  ## @param rbac.rules Custom RBAC rules to set
  ## e.g:
  ## rules:
  ##   - apiGroups:
  ##       - ""
  ##     resources:
  ##       - pods
  ##     verbs:
  ##       - get
  ##       - list
  ##
  rules: []
## @section Network Policy
##

## Network Policy configuration
## ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/
##
networkPolicy:
  ## @param networkPolicy.enabled Enable creation of NetworkPolicy resources
  ##
  enabled: true
  ## @param networkPolicy.allowExternal The Policy model to apply
  ## When set to false, only pods with the correct client label will have network access to the ports MySQL is
  ## listening on. When true, MySQL will accept connections from any source (with the correct destination port).
  ##
  allowExternal: true
  ## @param networkPolicy.allowExternalEgress Allow the pod to access any range of port and all destinations.
  ##
  allowExternalEgress: true
  ## @param networkPolicy.extraIngress [array] Add extra ingress rules to the NetworkPolicy
  ## e.g:
  ## extraIngress:
  ##   - ports:
  ##       - port: 1234
  ##     from:
  ##       - podSelector:
  ##           - matchLabels:
  ##               - role: frontend
  ##       - podSelector:
  ##           - matchExpressions:
  ##               - key: role
  ##                 operator: In
  ##                 values:
  ##                   - frontend
  ##
  extraIngress: []
  ## @param networkPolicy.extraEgress [array] Add extra ingress rules to the NetworkPolicy
  ## e.g:
  ## extraEgress:
  ##   - ports:
  ##       - port: 1234
  ##     to:
  ##       - podSelector:
  ##           - matchLabels:
  ##               - role: frontend
  ##       - podSelector:
  ##           - matchExpressions:
  ##               - key: role
  ##                 operator: In
  ##                 values:
  ##                   - frontend
  ##
  extraEgress: []
  ## @param networkPolicy.ingressNSMatchLabels [object] Labels to match to allow traffic from other namespaces
  ## @param networkPolicy.ingressNSPodMatchLabels [object] Pod labels to match to allow traffic from other namespaces
  ##
  ingressNSMatchLabels: {}
  ingressNSPodMatchLabels: {}
## @section Volume Permissions parameters
##

## Init containers parameters:
## volumePermissions: Change the owner and group of the persistent volume mountpoint to runAsUser:fsGroup values from the securityContext section.
##
volumePermissions:
  ## @param volumePermissions.enabled Enable init container that changes the owner and group of the persistent volume(s) mountpoint to `runAsUser:fsGroup`
  ##
  enabled: false
  ## @param volumePermissions.image.registry [default: REGISTRY_NAME] Init container volume-permissions image registry
  ## @param volumePermissions.image.repository [default: REPOSITORY_NAME/os-shell] Init container volume-permissions image repository
  ## @skip volumePermissions.image.tag Init container volume-permissions image tag (immutable tags are recommended)
  ## @param volumePermissions.image.digest Init container volume-permissions image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag
  ## @param volumePermissions.image.pullPolicy Init container volume-permissions image pull policy
  ## @param volumePermissions.image.pullSecrets Specify docker-registry secret names as an array
  ##
  image:
    registry: docker.io
    repository: bitnami/os-shell
    tag: 12-debian-12-r22
    digest: ""
    pullPolicy: IfNotPresent
    ## Optionally specify an array of imagePullSecrets.
    ## Secrets must be manually created in the namespace.
    ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
    ## e.g:
    ## pullSecrets:
    ##   - myRegistryKeySecretName
    ##
    pullSecrets: []
  ## @param volumePermissions.resourcesPreset Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if volumePermissions.resources is set (volumePermissions.resources is recommended for production).
  ## More information: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15
  ##
  resourcesPreset: "nano"
  ## @param volumePermissions.resources Set container requests and limits for different resources like CPU or memory (essential for production workloads)
  ## Example:
  ## resources:
  ##   requests:
  ##     cpu: 2
  ##     memory: 512Mi
  ##   limits:
  ##     cpu: 3
  ##     memory: 1024Mi
  ##
  resources: {}
## @section Metrics parameters
##

## Mysqld Prometheus exporter parameters
##
metrics:
  ## @param metrics.enabled Start a side-car prometheus exporter
  ##
  enabled: false
  ## @param metrics.image.registry [default: REGISTRY_NAME] Exporter image registry
  ## @param metrics.image.repository [default: REPOSITORY_NAME/mysqld-exporter] Exporter image repository
  ## @skip metrics.image.tag Exporter image tag (immutable tags are recommended)
  ## @param metrics.image.digest Exporter image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag
  ## @param metrics.image.pullPolicy Exporter image pull policy
  ## @param metrics.image.pullSecrets Specify docker-registry secret names as an array
  ##
  image:
    registry: docker.io
    repository: bitnami/mysqld-exporter
    tag: 0.15.1-debian-12-r24
    digest: ""
    pullPolicy: IfNotPresent
    ## Optionally specify an array of imagePullSecrets.
    ## Secrets must be manually created in the namespace.
    ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
    ## e.g:
    ## pullSecrets:
    ##   - myRegistryKeySecretName
    ##
    pullSecrets: []
  ## MySQL metrics container security context
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container
  ## @param metrics.containerSecurityContext.enabled MySQL metrics container securityContext
  ## @param metrics.containerSecurityContext.seLinuxOptions [object,nullable] Set SELinux options in container
  ## @param metrics.containerSecurityContext.runAsUser User ID for the MySQL metrics container
  ## @param metrics.containerSecurityContext.runAsGroup Group ID for the MySQL metrics container
  ## @param metrics.containerSecurityContext.runAsNonRoot Set MySQL metrics container's Security Context runAsNonRoot
  ## @param metrics.containerSecurityContext.allowPrivilegeEscalation Set container's privilege escalation
  ## @param metrics.containerSecurityContext.capabilities.drop Set container's Security Context runAsNonRoot
  ## @param metrics.containerSecurityContext.seccompProfile.type Set container's Security Context seccomp profile
  ## @param metrics.containerSecurityContext.readOnlyRootFilesystem Set container's Security Context read-only root filesystem
  ##
  containerSecurityContext:
    enabled: true
    seLinuxOptions: {}
    runAsUser: 1001
    runAsGroup: 1001
    runAsNonRoot: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
    seccompProfile:
      type: "RuntimeDefault"
    readOnlyRootFilesystem: true
  ## @param metrics.containerPorts.http Container port for http
  ##
  containerPorts:
    http: 9104
  ## MySQL Prometheus exporter service parameters
  ## Mysqld Prometheus exporter liveness and readiness probes
  ## ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
  ## @param metrics.service.type Kubernetes service type for MySQL Prometheus Exporter
  ## @param metrics.service.clusterIP Kubernetes service clusterIP for MySQL Prometheus Exporter
  ## @param metrics.service.port MySQL Prometheus Exporter service port
  ## @param metrics.service.annotations [object] Prometheus exporter service annotations
  ##
  service:
    type: ClusterIP
    port: 9104
    clusterIP: ""
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "{{ .Values.metrics.service.port }}"
  ## @param metrics.extraArgs.primary Extra args to be passed to mysqld_exporter on Primary pods
  ## @param metrics.extraArgs.secondary Extra args to be passed to mysqld_exporter on Secondary pods
  ## ref: https://github.com/prometheus/mysqld_exporter/
  ## E.g.
  ## - --collect.auto_increment.columns
  ## - --collect.binlog_size
  ## - --collect.engine_innodb_status
  ## - --collect.engine_tokudb_status
  ## - --collect.global_status
  ## - --collect.global_variables
  ## - --collect.info_schema.clientstats
  ## - --collect.info_schema.innodb_metrics
  ## - --collect.info_schema.innodb_tablespaces
  ## - --collect.info_schema.innodb_cmp
  ## - --collect.info_schema.innodb_cmpmem
  ## - --collect.info_schema.processlist
  ## - --collect.info_schema.processlist.min_time
  ## - --collect.info_schema.query_response_time
  ## - --collect.info_schema.tables
  ## - --collect.info_schema.tables.databases
  ## - --collect.info_schema.tablestats
  ## - --collect.info_schema.userstats
  ## - --collect.perf_schema.eventsstatements
  ## - --collect.perf_schema.eventsstatements.digest_text_limit
  ## - --collect.perf_schema.eventsstatements.limit
  ## - --collect.perf_schema.eventsstatements.timelimit
  ## - --collect.perf_schema.eventswaits
  ## - --collect.perf_schema.file_events
  ## - --collect.perf_schema.file_instances
  ## - --collect.perf_schema.indexiowaits
  ## - --collect.perf_schema.tableiowaits
  ## - --collect.perf_schema.tablelocks
  ## - --collect.perf_schema.replication_group_member_stats
  ## - --collect.slave_status
  ## - --collect.slave_hosts
  ## - --collect.heartbeat
  ## - --collect.heartbeat.database
  ## - --collect.heartbeat.table
  ##
  extraArgs:
    primary: []
    secondary: []
  ## Mysqld Prometheus exporter resource requests and limits
  ## ref: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
  ## We usually recommend not to specify default resources and to leave this as a conscious
  ## choice for the user. This also increases chances charts run on environments with little
  ## resources, such as Minikube. If you do want to specify resources, uncomment the following
  ## lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  ## @param metrics.resourcesPreset Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if metrics.resources is set (metrics.resources is recommended for production).
  ## More information: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15
  ##
  resourcesPreset: "nano"
  ## @param metrics.resources Set container requests and limits for different resources like CPU or memory (essential for production workloads)
  ## Example:
  ## resources:
  ##   requests:
  ##     cpu: 2
  ##     memory: 512Mi
  ##   limits:
  ##     cpu: 3
  ##     memory: 1024Mi
  ##
  resources: {}
  ## Mysqld Prometheus exporter liveness probe
  ## ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
  ## @param metrics.livenessProbe.enabled Enable livenessProbe
  ## @param metrics.livenessProbe.initialDelaySeconds Initial delay seconds for livenessProbe
  ## @param metrics.livenessProbe.periodSeconds Period seconds for livenessProbe
  ## @param metrics.livenessProbe.timeoutSeconds Timeout seconds for livenessProbe
  ## @param metrics.livenessProbe.failureThreshold Failure threshold for livenessProbe
  ## @param metrics.livenessProbe.successThreshold Success threshold for livenessProbe
  ##
  livenessProbe:
    enabled: true
    initialDelaySeconds: 120
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 3
  ## Mysqld Prometheus exporter readiness probe
  ## ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
  ## @param metrics.readinessProbe.enabled Enable readinessProbe
  ## @param metrics.readinessProbe.initialDelaySeconds Initial delay seconds for readinessProbe
  ## @param metrics.readinessProbe.periodSeconds Period seconds for readinessProbe
  ## @param metrics.readinessProbe.timeoutSeconds Timeout seconds for readinessProbe
  ## @param metrics.readinessProbe.failureThreshold Failure threshold for readinessProbe
  ## @param metrics.readinessProbe.successThreshold Success threshold for readinessProbe
  ##
  readinessProbe:
    enabled: true
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 3
  ## Prometheus Service Monitor
  ## ref: https://github.com/coreos/prometheus-operator
  ##
  serviceMonitor:
    ## @param metrics.serviceMonitor.enabled Create ServiceMonitor Resource for scraping metrics using PrometheusOperator
    ##
    enabled: false
    ## @param metrics.serviceMonitor.namespace Specify the namespace in which the serviceMonitor resource will be created
    ##
    namespace: ""
    ## @param metrics.serviceMonitor.jobLabel The name of the label on the target service to use as the job name in prometheus.
    ##
    jobLabel: ""
    ## @param metrics.serviceMonitor.interval Specify the interval at which metrics should be scraped
    ##
    interval: 30s
    ## @param metrics.serviceMonitor.scrapeTimeout Specify the timeout after which the scrape is ended
    ## e.g:
    ## scrapeTimeout: 30s
    ##
    scrapeTimeout: ""
    ## @param metrics.serviceMonitor.relabelings RelabelConfigs to apply to samples before scraping
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#relabelconfig
    ##
    relabelings: []
    ## @param metrics.serviceMonitor.metricRelabelings MetricRelabelConfigs to apply to samples before ingestion
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#relabelconfig
    ##
    metricRelabelings: []
    ## @param metrics.serviceMonitor.selector ServiceMonitor selector labels
    ## ref: https://github.com/bitnami/charts/tree/main/bitnami/prometheus-operator#prometheus-configuration
    ##
    ## selector:
    ##   prometheus: my-prometheus
    ##
    selector: {}
    ## @param metrics.serviceMonitor.honorLabels Specify honorLabels parameter to add the scrape endpoint
    ##
    honorLabels: false
    ## @param metrics.serviceMonitor.labels Used to pass Labels that are used by the Prometheus installed in your cluster to select Service Monitors to work with
    ## ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusspec
    ##
    labels: {}
    ## @param metrics.serviceMonitor.annotations ServiceMonitor annotations
    ##
    annotations: {}
  ## Prometheus Operator prometheusRule configuration
  ##
  prometheusRule:
    ## @param metrics.prometheusRule.enabled Creates a Prometheus Operator prometheusRule (also requires `metrics.enabled` to be `true` and `metrics.prometheusRule.rules`)
    ##
    enabled: false
    ## @param metrics.prometheusRule.namespace Namespace for the prometheusRule Resource (defaults to the Release Namespace)
    ##
    namespace: ""
    ## @param metrics.prometheusRule.additionalLabels Additional labels that can be used so prometheusRule will be discovered by Prometheus
    ##
    additionalLabels: {}
    ## @param metrics.prometheusRule.rules Prometheus Rule definitions
    ##  - alert: Mysql-Down
    ##    expr: absent(up{job="mysql"} == 1)
    ##    for: 5m
    ##    labels:
    ##      severity: warning
    ##      service: mariadb
    ##    annotations:
    ##      message: 'MariaDB instance {{`{{`}} $labels.instance {{`}}`}}  is down'
    ##      summary: MariaDB instance is down
    ##
    rules: []

```
这个安装的mysql主从无法启动，很费劲。
接下来进行单机部署mysql
mysql-deploymen.yaml
```yaml
root@ubuntu2:~/mysql# cat mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deployment
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        args:
          - --lower_case_table_names=1
          - --character-set-server=utf8mb4
          - --collation-server=utf8mb4_unicode_ci
          - --default-time-zone=+8:00
        image: mysql:8.0.30-debian
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: 123.com
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: /var/lib/mysql
          name: mysql-data
        - name: mysql-config
          mountPath: /etc/mysql
      volumes:
        - name: mysql-data
          hostPath:
            path: /root/data/mysql
            type: Directory
        - name: mysql-config
          hostPath:
            path: /root/data/mysql-config
            type: Directory


```

mysql-service.yaml

```yaml
root@ubuntu2:~/mysql# cat mysql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  type: NodePort
  selector:
    app: mysql
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
    nodePort: 30000
```


注意hostPath代表的是节点上的物理路径，需要先进行创建。