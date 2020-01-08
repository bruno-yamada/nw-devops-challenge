# NW ITOps Challenge

> "Esse desafio tem como objetivo entender o seu conhecimento sobre o mundo de microserviços e containers. Nós queremos construir uma API Hello World, efetuar o deploy em um container mínimo e expo-lo com um proxy reverso a frente (nginx) com suporte a TLS 1.2 utilizando certificado do letsencrypt."

Did terraform setup as an `extra`

# 1. Instantiate AWS stack using Terraform

Add your credentials to `./infra/terraform/nw_challenge.tf`

```
provider "aws" {
  access_key = "your-access-key"
  secret_key = "your-secret-key"
  region = "us-east-1"
}
```

Run:

```sh
terraform init
terraform plan
terraform apply
```

# 2. Execute ansible playbooks
- Set the proper host IP, user and SSH key in `./infra/ansible/hosts.inventory` as needed
- Add the SSL certificates to `./infra/ansible/certificates`
Run:
```
ansible-playbook nw_challenge.yml -i hosts.inventory
```

# 3. Possible Improvements
- Regarding the API:
  - kept the API as simple as possible, since it wasn't the focus of this challenge, so I added everything to the `main.py` file
  - Although it would add some bloat to the API, if needed, could easily improve this challenge by:
    - adding graylog logging support
    - spliting the classes into individual modules
- Regarding Terraform:
  - kept all resources in a single file to make it ease to grasp.
  - Could Refactor the terraform file in order to make better use of terraform variables, and split resources into individual files
- Regarding Ansible:
  - The Docker image could be pushed to an public or private registry instead of being builded by ansible, by using some CI/CD such as gitlab-ci, github-flow or circle-ci
  - Could make use of variables to allow for more programatic deployment if the domain name changed.
