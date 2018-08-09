# Samples of Ansible

There are ansible files for automatically configuring nginx balancer:
* [Playbook file](sample1/deploy_balancer)
* [Install git on a remote machine](sample1/roles/git/tasks/main.yml)
* [Install node on a remote machine](sample1/roles/node/tasks/main.yml)
* [Install and configure nginx](sample1/roles/nginxbalancer/tasks/main.yml)
* [Nginx config](sample1/roles/nginxbalancer/templates/example.conf)
* [Ansible handlers](sample1/roles/nginxbalancer/handlers/main.yml)

This example has three roles:
* [Install git on a remote machine](sample1/roles/git/tasks/main.yml)

It install git on the remote machine
* [Install node on a remote machine](sample1/roles/node/tasks/main.yml)

It install node on the remote machine

* [Install and configure nginx](sample1/roles/nginxbalancer/tasks/main.yml)

It install and configure nginx on the remote machine
