# eks-private-terraform
How to create an EKS Cluster using only private subnets from a pre-existing VPC using Terraform.



___
# [WTDDS] What the Demo doesn't show!

Before starting this journey with us, we need to explain what "What the demo doesn't show!" is. The idea for this series of posts in LinkedIn and Medium about technology came from a difficulty in finding materials on the internet about various problems that we @ghbonifacio, @marciofurukawa, @carsornelas go through during our day to day work as Data Engineers. So, after resolving several issues, we decided to document and bring these resolutions to the community in the form of a series of texts. I hope you enjoy it a lot, feel free to contact us to exchange ideas, we leave the contacts at the end of the texts! Let's go hand in the dough!.

Follow us on our social media and GitHub:
|     |     |     |     |
| --- | --- | --- | --- |
| `Carlos Ornelas`    | [Linkedin](https://www.linkedin.com/in/carlosornelas/)     | [Medium](https://medium.com/@carlosornelas.ti) | [GitHub](https://github.com/carsornelas)    |
| `Gabriel Bonifácio` | [Linkedin](https://www.linkedin.com/in/gabriel-bonifacio/) | [Medium](https://medium.com/@ghenriquee)       | [GitHub](https://github.com/ghbonifacio)    |
| `Marcio Furukawa`   | [Linkedin](https://www.linkedin.com/in/marciofcampos/)     | [Medium](https://medium.com/@marcio.furukawa)  | [GitHub](https://github.com/marciofurukawa) |



___
### Table of contents

- [1. Before starting](#1-before-starting)
  - [1.1. Terraform installation](#11-terraform-installation)
  - [1.2. kubectl installation](#12-kubectl-installation)
  - [1.3. AWS CLI installation](#13-aws-cli-installation)
  - [1.4. Arquitetura AWS necessária](#14-arquitetura-aws-necessária)
    - [1.4.1. Estrutura de VPC e Subnets](#141-estrutura-de-vpc-e-subnets)
    - [1.4.2. Estrutura de Roteamento e Gateways](#142-estrutura-de-roteamento-e-gateways)
- [2. Deploy da Infraestrutura](#2-deploy-da-infraestrutura)
  - [2.1. Aplicando o Terraform](#21-aplicando-o-terraform)
  - [2.2. Liberando acesso ao EKS](#22-liberando-acesso-ao-eks)
  - [2.3. Configurando o EKS Persistent Storage](#23-configurando-o-eks-persistent-storage)
  - [2.4. Restart do `coredns`](#24-restart-do-coredns)
  


___
# 1. Before starting

## 1.1. `Terraform` installation

In this project we are using `Terraform` version 1.1.7 and you can get it from the [official Hashicorp link](https://releases.hashicorp.com/terraform/), or executing the following steps if your Operational System is a Linux Ubuntu ditro:

1- Updating the `apt`:
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
```

2- Installing `Terraform` in the specific version that we need:
```bash
sudo apt-get install terraform=1.1.7
```

3- Testing the installation:
```bash
terraform --version
```
PS: The command should return the version 1.1.7.

___
[go to the top](#table-of-contents)
___



## 1.2. `kubectl` installation

The `kubectl` is the command line interface (CLI) that we are going to use to communicate to Kubernetes. You can follow the [official link](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to get the installation or the following steps:

PS: There's no version restriction, so you can install the `latest` release for Linux Ubuntu distro.

1- Getting the latest version:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

2- (Optional) Validating the binary getting the checksum:
```bash
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
```

3- (Optional) Comparing both:
```bash
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```
PS: If it's valid, you're going to see the return:
```
kubectl: OK
```

4- Installing the `kubectl`:
```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

5- Testing the installation:
```
kubectl version --client
```
PS: The command should return the latest version of the kubectl.

___
[go to the top](#table-of-contents)
___



## 1.3. `AWS CLI` installation

The `AWS CLI` is the command line interface (CLI) that we are going to use to communicate to Amazon Web Services. You can follow the [official link](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to get the installation.

PS: There's no version restriction, so you can install the `latest` release for Linux Ubuntu distro.

___
[go to the top](#table-of-contents)
___



## 1.4. Arquitetura AWS necessária

Os scripts neste repositório só executarão com sucesso se houver uma estrutura de VPC contendo subnets e gateways criada previamente, visto que os mesmos já existiam antes de construirmos toda a infraestrutura e portanto não foram colocados no script.

___
[ir para o topo](#índice-table-of-contents)
___



### 1.4.1. Estrutura de VPC e Subnets

Contamos que já deve existir uma VPC com pelo menos 3 subnets públicas e 3 subnets privadas em availability zones diferentes. No caso da infra atual, foram criadas 6 de cada, ficando da seguinte forma:

![Estrutura de VPC e Subnets](readme_data/pics/diagrama_01_subnets.png "Estrutura de VPC e Subnets")

___
[ir para o topo](#índice-table-of-contents)
___



### 1.4.2. Estrutura de Roteamento e Gateways

As subnets públicas deverão estar ligadas a um Internet Gateway, enquanto as privadas deverão se conectar a um NAT Gateway e este, por sua vez, a um Elastic IP e também se comunicando com uma subnet pública.

Todas as subnets, públicas e privadas, se comunicarão com a rede interna do XXXXXXX através de um Transit Gateway, ficando da seguinte forma:

![Estrutura de Roteamento e Gateways](readme_data/pics/diagrama_02_route_tables.png "Estrutura de Roteamento e Gateways")

___
[ir para o topo](#índice-table-of-contents)
___




# 2. Deploy da Infraestrutura

## 2.1. Aplicando o Terraform

1- Acessar a pasta deste repositório:
```
cd <path>/infra-dados
```

2- Iniciar o Terraform:
```
terraform init
```

3- Formatar os arquivos:
```
terraform fmt
```

4- Validar os arquivos:
```
terraform validate
```

5- Aplicar os scripts em PRD:
```
terraform apply --var-file="env/prd.tfvars"
```
Obs: Revise se não há nenhuma variável fixada nos scripts com o nome de "hml", exceto no arquivo: `dev/hml.tfvars`

6- Confirme as ações do terraform digitando `yes` e teclando `enter`:
```
Do you want to perform these actions?

  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
  Enter a value: yes
```

___
[ir para o topo](#índice-table-of-contents)
___



## 2.2. Liberando acesso ao EKS

1- Atualizando o contexto local:
```
aws eks update-kubeconfig --region us-east-1 --name eks-prd-dados
```

2- Adicionando usuários como admin:
```
kubectl edit -n kube-system configmap/aws-auth
```

3- Será aberto o arquivo de configuração e precisaremos adicionar um bloco no mesmo nível de `mapRoles` chamado `mapUsers` com os usuários que queremos que se tornem `masters` do cluster EKS, por exemplo:

Bloco a ser adicionado:
```
  mapUsers: |
    - userarn: arn:aws:iam::000000000000:user/nome.sobrenome
      username: nome.sobrenome
      groups:
        - system:masters
```

Então o arquivo será aberto desta forma:
```
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
kind: ConfigMap
metadata:
  creationTimestamp: "2022-09-18T19:15:14Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "1256"
  uid: a666c666-14e0-4666-af1e-50666ccc6666
```

E com o bloco `mapUsers` ficaria desta forma:
```
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
    - userarn: arn:aws:iam::000000000000:user/nome.sobrenome
      username: nome.sobrenome
      groups:
        - system:masters
    - userarn: etc...
      username: etc...
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

Se tiver alterado corretamente, atentando-se a identação, será retornada a mensagem:
```
configmap/aws-auth edited
```

___
[ir para o topo](#índice-table-of-contents)
___



## 2.3. Configurando o EKS Persistent Storage

É necessário configurar o `EKS Persistent Storage` no cluster EKS que acabamos de subir, caso contrário o Airflow não conseguirá inicializar. Esta configuração foi retirada do [link oficial da AWS](https://aws.amazon.com/pt/premiumsupport/knowledge-center/eks-persistent-storage/).

Seguir os passos de 1 a 9 da seção `Option A: Deploy and test the Amazon EBS CSI driver`.

Nota: Este é um pré-requisito para que o pod de PostgreSQL do Airflow consiga ser instanciado e criar seu respectivo volume.

___
[ir para o topo](#índice-table-of-contents)
___



## 2.4. Restart do `coredns`

Após a subida do cluster é bem provável que ele ainda não consiga resolver os hostnames do XXXXXXX e para isso será preciso reiniciar o serviço de `coredns` executando o seguinte comando dentro do EKS:

```
kubectl rollout restart -n kube-system deployment/coredns
```

Desta forma o serviço será reiniciado e não ocorrerá mais problemas durante a instalação do ArgoCD, Airflow e outras aplicações.

___
[ir para o topo](#índice-table-of-contents)
___
