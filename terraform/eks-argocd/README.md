# GitOps-Bridge: KubeCon/ArgoCon NA 2023

This tutorial guides you through deploying an Amazon EKS cluster with addons configured via ArgoCD, employing the [GitOps Bridge Pattern](https://github.com/gitops-bridge-dev).

<img src="https://raw.githubusercontent.com/gitops-bridge-dev/gitops-bridge/main/argocd/iac/terraform/examples/eks/getting-started/static/gitops-bridge.drawio.png" width=100%>


The [GitOps Bridge Pattern](https://github.com/gitops-bridge-dev) enables Kubernetes administrators to utilize Infrastructure as Code (IaC) and GitOps tools for deploying Kubernetes Addons and Workloads. Addons often depend on Cloud resources that are external to the cluster. The configuration metadata for these external resources is required by the Addons' Helm charts. While IaC is used to create these cloud resources, it is not used to install the Helm charts. Instead, the IaC tool stores this metadata either within GitOps resources in the cluster or in a Git repository. The GitOps tool then extracts these metadata values and passes them to the Helm chart during the Addon installation process. This mechanism forms the bridge between IaC and GitOps, hence the term "GitOps Bridge."

Try out the [Getting Started](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/getting-started) example.

Additional examples available on the [GitOps Bridge Pattern](https://github.com/gitops-bridge-dev):
- [argocd-ingress](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/argocd-ingress)
- [aws-secrets-manager](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/aws-secrets-manager)
- [crossplane](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/crossplane)
- [external-secrets](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/external-secrets)
- [multi-cluster/distributed](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/multi-cluster/distributed)
- [multi-cluster/hub-spoke](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/multi-cluster/hub-spoke)
- [multi-cluster/hub-spoke-shared](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/multi-cluster/hub-spoke-shared)
- [private-git](https://github.com/gitops-bridge-dev/gitops-bridge/tree/main/argocd/iac/terraform/examples/eks/private-git)



## Prerequisites
Before you begin, make sure you have the following command line tools installed:
- git
- terraform
- kubectl
- argocd

## (Optional) Fork the GitOps git repositories
See the appendix section [Fork GitOps Repositories](#fork-gitops-repositories) for more info on the terraform variables to override.


## Deploy the EKS Cluster
Initialize Terraform and deploy the EKS cluster:
```shell
terraform init
terraform apply -auto-approve
```
Retrieve `kubectl` config, then execute the output command:
```shell
terraform output -raw configure_kubectl
```

Terraform will add GitOps Bridge Metadata to the ArgoCD secret.
The annotations contain metadata for the addons' Helm charts and ArgoCD ApplicationSets.
```shell
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster -o json | jq '.items[0].metadata.annotations'
```
The output looks like the following:
```json
{
  "addons_repo_basepath": "gitops/",
  "addons_repo_path": "bootstrap/control-plane/addons",
  "addons_repo_revision": "main",
  "addons_repo_url": "git@github.com:gitops-bridge-dev/kubecon-2023-na-argocon",
  "workload_repo_basepath": "gitops/",
  "workload_repo_path": "apps",
  "workload_repo_revision": "main",
  "workload_repo_url": "git@github.com:gitops-bridge-dev/kubecon-2023-na-argocon"
  "aws_account_id": "0123456789",
  "aws_cloudwatch_metrics_iam_role_arn": "arn:aws:iam::0123456789:role/aws-cloudwatch-metrics-20231029150636632700000028",
  "aws_cloudwatch_metrics_namespace": "amazon-cloudwatch",
  "aws_cloudwatch_metrics_service_account": "aws-cloudwatch-metrics",
  "aws_cluster_name": "ex-eks-akuity",
  "aws_for_fluentbit_iam_role_arn": "arn:aws:iam::0123456789:role/aws-for-fluent-bit-20231029150636632700000029",
  "aws_for_fluentbit_log_group_name": "/aws/eks/ex-eks-akuity/aws-fluentbit-logs-20231029150605912500000017",
  "aws_for_fluentbit_namespace": "kube-system",
  "aws_for_fluentbit_service_account": "aws-for-fluent-bit-sa",
  "aws_load_balancer_controller_iam_role_arn": "arn:aws:iam::0123456789:role/alb-controller-20231029150636630700000025",
  "aws_load_balancer_controller_namespace": "kube-system",
  "aws_load_balancer_controller_service_account": "aws-load-balancer-controller-sa",
  "aws_region": "us-west-2",
  "aws_vpc_id": "vpc-0d1e6da491803e111",
  "cert_manager_iam_role_arn": "arn:aws:iam::0123456789:role/cert-manager-20231029150636632300000026",
  "cert_manager_namespace": "cert-manager",
  "cert_manager_service_account": "cert-manager",
  "cluster_name": "in-cluster",
  "environment": "dev",
  "external_dns_namespace": "external-dns",
  "external_dns_service_account": "external-dns-sa",
  "external_secrets_iam_role_arn": "arn:aws:iam::0123456789:role/external-secrets-20231029150636632600000027",
  "external_secrets_namespace": "external-secrets",
  "external_secrets_service_account": "external-secrets-sa",
  "karpenter_iam_role_arn": "arn:aws:iam::0123456789:role/karpenter-20231029150636630500000024",
  "karpenter_namespace": "karpenter",
  "karpenter_node_instance_profile_name": "karpenter-ex-eks-akuity-2023102915060627290000001a",
  "karpenter_service_account": "karpenter",
  "karpenter_sqs_queue_name": "karpenter-ex-eks-akuity",
}
```
The labels offer a straightforward way to enable or disable an addon in ArgoCD for the cluster.
```shell
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster -o json | jq '.items[0].metadata.labels' | grep -v false | jq .
```
The output looks like the following:
```json
{
  "argocd.argoproj.io/secret-type": "cluster",
  "aws_cluster_name": "ex-eks-akuity",
  "cluster_name": "in-cluster",
  "enable_argocd": "true",
  "enable_aws_cloudwatch_metrics": "true",
  "enable_aws_ebs_csi_resources": "true",
  "enable_aws_for_fluentbit": "true",
  "enable_aws_load_balancer_controller": "true",
  "enable_cert_manager": "true",
  "enable_external_dns": "true",
  "enable_external_secrets": "true",
  "enable_ingress_nginx": "true",
  "enable_karpenter": "true",
  "enable_kyverno": "true",
  "enable_metrics_server": "true",
  "environment": "dev",
  "kubernetes_version": "1.28"
}
```

### Monitor GitOps Progress for Addons
Wait until all the ArgoCD applications' `HEALTH STATUS` is `Healthy`. Use Crl+C to exit the `watch` command
```shell
watch kubectl get applications -n argocd
```

### Verify the Addons
Verify that the addons are ready:
```shell
kubectl get deployment -A
```

## Access ArgoCD
Access ArgoCD's UI, run the command from the output:
```shell
terraform output -raw access_argocd
```

### Monitor GitOps Progress for Workloads
Watch until the Workloads ArgoCD Application is `Healthy`
```shell
watch kubectl get -n argocd applications -l workload=true
```
Wait until the ArgoCD Applications `HEALTH STATUS` is `Healthy`. Crl+C to exit the `watch` command

### Verify the Application
Verify that the application configuration is present and the pod is running:
```shell
kubectl get -n guestbook deployments,service,ep,ingress
```
The expected output should look like the following:
```text
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/guestbook-ui   1/1     1            1           3m7s

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/guestbook-ui   ClusterIP   172.20.211.185   <none>        80/TCP    3m7s

NAME                     ENDPOINTS        AGE
endpoints/guestbook-ui   10.0.31.115:80   3m7s

NAME                   CLASS   HOSTS   ADDRESS                          PORTS   AGE
ingress/guestbook-ui   nginx   *       <>.elb.us-west-2.amazonaws.com   80      3m7s
```
### Access the Application using AWS Load Balancer
Verify the application endpoint health using `curl`:
```shell
kubectl exec -n guestbook deploy/guestbook-ui -- \
curl -I -s $(kubectl get -n ingress-nginx svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
The first line of the output should have `HTTP/1.1 200 OK`.

Retrieve the ingress URL for the application, and access in the browser:
```shell
echo "Application URL: http://$(kubectl get -n ingress-nginx svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```


### Container Metrics
Check the application's CPU and memory metrics:
```shell
kubectl top pods -n guestbook
```
Check all pods CPU and memory metrics:
```shell
kubectl top pods -A
```

## Destroy the EKS Cluster
To tear down all the resources and the EKS cluster, run the following command:
```shell
./destroy.sh
```

## Appendix

## Fork GitOps Repositories
To modify the `values.yaml` file for addons or the workload manifest files (.ie yaml), you'll need to fork this repository: [gitops-bridge-dev/kubecon-2023-na-argocon](https://github.com/gitops-bridge-dev/kubecon-2023-na-argocon).
After forking, update the following environment variables to point to you fork, replacing the default values.
```shell
export TF_VAR_gitops_addons_org=git@github.com:<org or user>
export TF_VAR_gitops_addons_repo=kubecon-2023-na-argocon
export TF_VAR_gitops_addons_revision=main

export TF_VAR_gitops_workload_org=git@github.com:<org or user>
export TF_VAR_gitops_workload_repo=kubecon-2023-na-argocon
export TF_VAR_gitops_workload_revision=main
```

### Manually deploy Bootstrap apps

Only applicable if you don't deploy the bootstrap by setting the following variable to false (default true)
```shell
export TF_VAR_enable_gitops_auto_bootstrap=false
```

#### Deploy the Addons
Bootstrap the addons using ArgoCD:
```shell
kubectl apply -f ../../gitops/bootstrap/control-plane/exclude/addons.yaml
```

#### Deploy the Workloads
Deploy a sample application located in [../../gitops/apps/guestbook](../../gitops/apps/guestbook) using ArgoCD:
```shell
kubectl apply -f ../../gitops/bootstrap/workloads/exclude/workloads.yaml
```
