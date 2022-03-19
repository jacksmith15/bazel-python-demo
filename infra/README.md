# Local infrastructure, for testing delivery of built artifacts

## Set-up

Requires [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) and [ctlptl](https://github.com/tilt-dev/ctlptl#how-do-i-install-it).

## Usage

Create the cluster:

```bash
ctlptl apply -f cluster.yaml
```

This creates a Kubernetes cluster and image registry. The image registry is available at localhost:5005, and can be pushed to by the Bazel build steps.


Finally, to tear down the cluster:

```bash
ctlptl delete -f cluster.yaml
```
