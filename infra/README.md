# Local infrastructure, for testing delivery of built artifacts

## Set-up

Requires [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) and [ctlptl](https://github.com/tilt-dev/ctlptl#how-do-i-install-it).

## Usage

#### Create the cluster and associated resources:

```bash
infra/up
```

This will create an image registry (at `localhost:5005`) and a kubernetes cluster with a number of resources.

> :memo: You can also re-run this to propagate any changes to the `cluster/kustomize/` directory.


#### Deploy applications built by Bazel

```bash
bazel build //...  # Run the build
./publish.sh  # Publish the images
infra/deploy  # Deploy the apps with the latest images
```

#### Patch `/etc/hosts` file for ease of testing (this will be reverted when you interrupt it):

```bash
sudo infra/dns
```

> :information_source: Whilst `infra/dns` is running, you can access resources in the cluster via hostname. Try opening http://pypi.cluster.local in your browser.

#### Tear down the infra:

```bash
infra/down
```
