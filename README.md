# eks-private-terraform
How to create an EKS Cluster using only private subnets from a pre-existing VPC using Terraform.



___
# [WTDDS] What the Demo doesn't show!

Before starting this journey with us, we need to explain what "What the demo doesn't show!" is. The idea for this series of posts in LinkedIn and Medium about technology came from a difficulty in finding materials on the internet about various problems that we [@ghbonifacio](https://github.com/ghbonifacio), [@marciofurukawa](https://github.com/marciofurukawa), [@carsornelas](https://github.com/carsornelas) go through during our day to day work as Data Engineers. So, after solving several issues, we decided to document and bring these resolutions to the community in the form of a series of texts in Medium and LinkedIn. I hope you enjoy it a lot, feel free to contact us to exchange ideas, we leave the contacts here! Let's go hand in the dough!

Follow us on our social media or GitHub!
| Collaborators |     |     |     |
| --- | --- | --- | --- |
| `Carlos Ornelas`    | [LinkedIn](https://www.linkedin.com/in/carlosornelas/)     | [Medium](https://medium.com/@carlosornelas.ti) | [GitHub](https://github.com/carsornelas)    |
| `Gabriel Bonifácio` | [LinkedIn](https://www.linkedin.com/in/gabriel-bonifacio/) | [Medium](https://medium.com/@ghenriquee)       | [GitHub](https://github.com/ghbonifacio)    |
| `Marcio Furukawa`   | [LinkedIn](https://www.linkedin.com/in/marciofcampos/)     | [Medium](https://medium.com/@marcio.furukawa)  | [GitHub](https://github.com/marciofurukawa) |



___
### Table of contents

- [1. AWS Architecture scenario](#1-aws-architecture-scenario)
  - [1.1. Pre-existing resources in AWS: VPC and Subnets
](#11-pre-existing-resources-in-aws-vpc-and-subnets)
  - [1.2. Pre-existing resources in AWS: Route Tables and Gateways](#12-pre-existing-resources-in-aws-route-tables-and-gateways)
- [2. Before starting](#2-before-starting)
  - [2.1. Terraform installation](#21-terraform-installation)
  - [2.2. kubectl installation](#22-kubectl-installation)
  - [2.3. AWS CLI installation](#23-aws-cli-installation)
- [3. EKS Deployment](#3-eks-deployment)
  - [3.1. Customizing your EKS Cluster](#31-customizing-your-eks-cluster)
  - [3.2. Applying the Terraform script](#32-applying-the-terraform-script)
  - [3.3. Granting access to EKS](#33-granting-access-to-eks)
  - [3.4. Configurating the EKS Persistent Storage](#34-configurating-the-eks-persistent-storage)
  - [3.5. Restarting the coredns service](#35-restarting-the-coredns-service)



___
# 1. AWS Architecture

All the tutorials that we found in the internet taught us how to create an EKS Cluster from scratch, creating the VPC and all the other resources, but `what the demo doesn't show` is that, in real life, this scenario will be satisfied just if you're starting a project from zero, but if you need to create a new EKS Cluster, using node groups for autoscalling, in a pre-existing VPC, using only private subnets, so you're going to follow a lot of specific rules.

Here we are going to talk about all the errors that we faced during this deployment and maybe this source code could help you to overcome them!

So let's go!

___
[go to the top](#table-of-contents)
___



## 1.1. Pre-existing resources in AWS: VPC and Subnets

An EKS must use at least 3 subnets in different availability zones, so for our scenario we have those resources (that already exists and won't be created from the scripts in this GitHub repository):

![VPC and Subnets structure](readme_data/pics/aws_diagram_01_subnets.png "VPC and Subnets structure")

As you can see, here we have 3 pair of subnets: one is `private` and another is `public` in the AWS region: `us-east-1` and each pair is located in a different availability zone: `a`, `b` and `c`.

___
[go to the top](#table-of-contents)
___



## 1.2. Pre-existing resources in AWS: Route Tables and Gateways

Talking about a real scenario, we're going to communicate our applications to the internet and to the company (or customer) network, so we're going to need 3 different gateways: `NAT Gateway`, `Transit Gateway` and `Internet Gateway`. As the VPC and Subnets, those are not going to be created by the terraform scripts in this repository.

![Route Tables and Gateways structure](readme_data/pics/aws_diagram_02_route_tables.png "Route Tables and Gateways structure")

As you can see we have three `Route Tables`:
- the `RT_MAIN` because it's mandatory to have a default Route Table during the VPC creation, but it's not associated to any Subnet;
- the `RT_TRANSIT_GT` that will be used by the `private subnets`;
- and the `RT_INTERNET_GT` that will be used by the `public subnets`.

The public subnets are going to access the company network through the `Transit Gateway` and the internet through the `Internet Gateway`, so all the public subnets MUST HAVE the setting: `Enable auto-assign public IPv4 address` = activated (see more details in the AWS official Documentation [here](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html) and [here](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-subnet-configuration/)).

The private subnets are going to access the company network through the `Transit Gateway`, but the internet are going to reach through a `NAT Gateway`. This `NAT Gateway` are going to be related a `public subnet` (in our diagram it'll be the SUBNET_PUB_1A) and all the private subnets MUST HAVE the configuration: `Enable auto-assign public IPv4 address` = deactivated and it must have an `Elastic IP` created.

___
[go to the top](#table-of-contents)
___



# 2. Before starting

## 2.1. `Terraform` installation

In this project we are using `Terraform` version 1.1.7 and you can get it from the [Hashicorp official website](https://releases.hashicorp.com/terraform/), or executing the following steps if your Operational System is a Linux Ubuntu ditro:

1- Updating the `apt` (Advanced Packaging Tool):
```bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

$ sudo apt-get update
```

2- Installing `Terraform` in the specific version that we need:
```bash
$ sudo apt-get install terraform=1.1.7
```

3- Testing the installation:
```bash
$ terraform --version
```
Note: The command should return the version 1.1.7.

___
[go to the top](#table-of-contents)
___



## 2.2. `kubectl` installation

The `kubectl` is the command line interface (CLI) that we are going to use to communicate to Kubernetes. You can follow the [Kubernetes official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to get the installation or the following steps:

PS: There's no version restriction, so you can install the `latest` release for Linux Ubuntu distro.

1- Getting the latest version:
```bash
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

2- (Optional) Validating the binary getting the checksum:
```bash
$ curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
```

3- (Optional) Comparing both:
```bash
$ echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```
Note: If it's valid, you're going to see the return:
```
kubectl: OK
```

4- Installing the `kubectl`:
```bash
$ sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

5- Testing the installation:
```
$ kubectl version --client
```
Note: The command should return the latest version of the kubectl.

___
[go to the top](#table-of-contents)
___



## 2.3. `AWS CLI` installation

The `AWS CLI` is the command line interface (CLI) that we are going to use to communicate to Amazon Web Services. You can follow the [AWS official documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to get the installation or the following steps:

PS: There's no version restriction, so you can install the `latest` release for Linux Ubuntu distro.

1- Getting the installer:
```bash
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

$ unzip awscliv2.zip

$ sudo ./aws/install
```

2- Unzipping the installer:
```bash
$ unzip awscliv2.zip
```

3- Running the installer:
```bash
$ ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
```

4- Testing the installation:
```bash
$ aws --version
```
Note: The command should return the latest version of the AWS CLI.

5- Configure your AWS Credentials using `aws configure`:
```bash
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE # your access key ID here
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY # your secret access key here
Default region name [None]: us-west-2 # your aws region here
Default output format [None]: json # the output format you prefer
```
Note: If you don't have any AWS Access Key ID and Secret Key, see the [AWS official documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

___
[go to the top](#table-of-contents)
___



# 3. EKS Deployment

## 3.1. Customizing your EKS Cluster

In this repo we organize all the EKS configuration in terraform variables, so we recommed to check and edit the content of the file: `end/prd.tfvars` to your own need. If you are not sure about which confuguration put on that, see the AWS official documentation [here](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) and [here](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html).

![PRD tfvars editable file](readme_data/pics/print_prd_tfvars.png "PRD tfvars editable file")

This structure has been created because you can create lots of different files with different configurations for each environment you need and keep them in the same terraform repository.

Note: Don't forget to change the VPC and Subnets IDs.

___
[go to the top](#table-of-contents)
___



## 3.2. Applying the Terraform script

1- Access this repository path:
```bash
$ cd <path>/eks-private-terraform
```

2- Initiate Terraform:
```bash
$ terraform init
```

3- Check and format the terraform files:
```bash
$ terraform fmt
```

4- Validate the terraform files:
```bash
$ terraform validate
```

5- Apply the scripts using the environment you want, for instance PRD:
```bash
$ terraform apply --var-file="env/prd.tfvars"
```

6- Confirm the actions typing `yes`:
```bash
Do you want to perform these actions?

  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
  Enter a value: yes
```

Note: The EKS Cluster creation will depend on the number and kind of resources put in the `env/prd.tfvars` file, but it wouldn't take more than 20 minutes.

___
[go to the top](#table-of-contents)
___



## 3.3. Granting access to EKS

1- Updating your local kubernetes context:
```bash
$ aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
```

Note: In this script, running for PRD environment, the cluster name should be:
```bash
$ aws eks update-kubeconfig --region us-east-1 --name eks-prd-poc-private-terraform
```

2- Adding users as master:
```bash
$ kubectl edit -n kube-system configmap/aws-auth
```

3- It'll be opened the configuration file and we need to add the `mapUsers` block in the same level to `mapRoles` block. In this block we need to put the AWS users in the `system:masters` group, for instance:

Example of `mapUsers` block:
```bash
  mapUsers: |
    - userarn: arn:aws:iam::000000000000:user/nome.sobrenome ## put your User ARN here
      username: nome.sobrenome ## put your username here
      groups:
        - system:masters
```

So, the configuration file should like that:
```bash
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::000000000000:role/eks-prd-node-eks-node-group-20220918190130000000000000
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: |
    - userarn: arn:aws:iam::000000000000:user/nome.sobrenome ## put your User ARN here
      username: nome.sobrenome ## put your username here
      groups:
        - system:masters
kind: ConfigMap
metadata:
  creationTimestamp: "2022-09-18T19:15:14Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "1256"
  uid: a666c666-14e0-4666-af1e-50666ccc6666
```

Note: If you typed correctly (repecting the identation) you'll receive the message:
```bash
configmap/aws-auth edited
```

If you want more details about this configuration, please read the [AWS official documentation](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html).

___
[go to the top](#table-of-contents)
___



## 3.4. Configurating the EKS Persistent Storage

(Optional) We strongly recommend you to configurate the `EKS Persistent Storage` in the EKS Cluster that we have just created, because we had some problems creating applications in the EKS as Apache Airflow during the Volume allocation, but you can skip this step and see if your apps and pods are executing without problems.

If you want to configurate it, you need to follow the `steps 1 to 9` in the section: `Option A: Deploy and test the Amazon EBS CSI driver` in the [AWS official documentation](https://aws.amazon.com/pt/premiumsupport/knowledge-center/eks-persistent-storage/).

___
[go to the top](#table-of-contents)
___



## 3.5. Restarting the `coredns` service

(Optional) Maybe your EKS Cluster couldn't resolve the hostnames from your Company Network (through the Transit Gateway TG_COMPANY in our schema in the topic [1.2. Pre-existing resources in AWS: Route Tables and Gateways](#12-pre-existing-resources-in-aws-route-tables-and-gateways)).

This is another optional step that we needed to execute because we used some applications as ArgoCD and Apache Airflow and maybe you don't need to do that, but if you want to avoid this problem we need to restart the `coredns` service executing the following command in the EKS:

```bash
kubectl rollout restart -n kube-system deployment/coredns
```

___
[go to the top](#table-of-contents)
___
