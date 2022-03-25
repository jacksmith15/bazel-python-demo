# Fake DNS

This directory contains configuration of hostnames which should get resolved to the local cluster.

The `infra/dns` script can be run to patch these into your `/etc/hosts` file, e.g.

```
$ sudo infra/dns
Made back-up of /etc/hosts at /etc/hosts.1648639080.bak
Successfully patched /etc/hosts
Press Ctrl+C to stop patching hosts
```
