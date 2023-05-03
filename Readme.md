## K8s Symfony Deployer

<hr>

### Kubernetes Default Commands

1. Change the default namespace
   ```
   kubectl config set-context --current --namespace=<namespace>
   ```
2. Create ImagePullSecret  "regcred"
   ``` 
   kubectl create secret generic regcred \
   --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
   --type=kubernetes.io/dockerconfigjson
   ```

<hr>

### Install Dependencies:

1. semver
    ```
    npm i -g semver
   ```


2. yq
    ```
   version: 4.16.2
   github: https://github.com/mikefarah/yq/
   ```
   ```
   wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/4.16.2/download/yq_linux_amd64 
   &&  chmod a+x /usr/local/bin/yq
   ```

<hr>

### Setting up a Mongodb Replica Set

1. Apply all the files in the directory
    ```
   kubectl apply -f k8s/mongodb -n <your-namespace>
   ```

2. List all the pods
    ```
   kubectl get pods -n <your-namespace> 
   ```

2. Select any one pod to act as the primary node in RS.
    ```
   kubectl exec -it <pod-name> -- bash
   mongosh -u <username> 
   
   rs.intitiate();
   ```

4. Add the members to the replica set.
    ```
   rs.add({});
   ```