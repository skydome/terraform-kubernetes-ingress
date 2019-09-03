# terraform-kubernetes-ingress
Ingress Controller on Kubernetes

### Please do not get confused with NginxInc Ingress Controller. This module installs kubernetes ingress controller maintained at https://github.com/kubernetes/ingress-nginx

Tested on GKE. According to [original tutorial from kubernetes falks](https://kubernetes.github.io/ingress-nginx/deploy/), Aws and Azure needs different kind of setup. Please see the deployment differences from [here](https://kubernetes.github.io/ingress-nginx/deploy/)  


## How does it work?

This module creates following resources;

- config_maps
- roles/role_bindings with necessary permissions
- cluster_role/cluster_role_bindings with necessary permissions
- a service with LoadBalancer configured
- a deployment with kubernetes/ingress controller image running within the given namespace(only listening ingress events specified for this namespace) for multi-namespace deployments

## Inputs

- **namespace**     : kubernetes namespace to be deployed
- **replicacount**  : replica instance count for Ingress Controller

## Dependencies

Terraform Kubernetes Provider

## Tested With

- terraform-providers/kubernetes : 1.9.0
- quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.25.1	docker image
- kubernetes 1.13.7-gke.8

## Credits

This module was initially generated following the original tutorial of kubernetes ingress https://kubernetes.github.io/ingress-nginx/deploy a [k2tf](https://github.com/sl1pm4t/k2tf) project.
