

## Create Secret for Private Image Repository

#### YAML
```
apiVersion: v1
kind: Secret
metadata:
name: my-docker-secret
annotations:
kubernetes.io/dockerconfigjson: "true"
type: kubernetes.io/dockerconfigjson
data:
.dockerconfigjson: <base64-encoded contents of the Docker config.json file>
```

#### Command

```
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```
