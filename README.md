# Inception-of-Things

42 Left-curved system administration project

## Setup Host VM

Within the Host Machine, we configure a Host VM (one that will run nested VMs)  

We use `libvirt` (Virtual Machine Manager) as our hypervisor.  

### Config

> Name: IoT-host  
> OS: Ubuntu Server LTS 22.04.5  
> Memory: 12288 MB (squeezing GitLab into 12GiB :| )  
> CPUs: 8  
> Storage: qcow2 disk (25 GB)  
> Network: User (bridge not possible in our user session)  
> Ports forwarded: 2242 (SSH), 8888 (Kubernetes API), 8080 (ArgoCD), 8081 (GitLab)

---

### Cloud Init

Hands-off automated setup of the Virtual Machine:  

```bash
make install

# Connect to the VM console
make connect
```

Login into the host VM with user: `inception` and password that you provided at the start  

Ready to roll...  

**Proceed to [P0](#p0)**  

---

### Alternative: XML import

A more manual approach.

```bash
make import
```

#### Install

- Open the machine in VMM  
- Run installation with defaults  
- After installation completes:  

    1. reboot,  
    2. login to verify setup,  
    3. make snapshot (View -> Snapshots -> +),  
    4. Run: `systemctl enable serial-getty@ttyS0.service` and authenticate with password  
    5. Run: `systemctl start serial-getty@ttyS0.service` and authenticate with password  
    6. shutdown.  

- Configure mounting our source directory inside VM:  
View -> Details -> Add Hardware -> Filesystem -> Driver: virtio-9p, Source: <this dir>, Target: iot  

#### Provision

Start VM with connection to its console:  

```bash
make connect
# OR
# virsh -c qemu:///session start IoT-host --console
```

Login using your VM credentials.  

*Note: You can use `Ctrl+]` to exit the VM console.*  

Update repositories and install core packages:  

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install qemu-guest-agent git curl ansible
```

---

## P0

#### [Optional] SSH key

To access the VM via SSH, copy your public key contents to the authorized keys file:

```bash
echo <SSH PUBLIC KEY CONTENTS> >> ~/.ssh/authorized_keys
```

Now you can access the VM via SSH using your private key:

```bash
ssh -i <PATH TO PRIVATE KEY> -p 2242 inception@127.0.0.1
```

#### Mount the project as external filesystem

```bash
sudo mount -t 9p -o trans=virtio,version=9p2000.L iot /mnt

# Make a copy owned by our user to avoid issues with write permissions
cp -r /mnt ~
```

#### Call ansible playbook  

```bash
cd ~/mnt/host
ansible-playbook -i hosts.ini provision_vm_host.yaml
sudo reboot now
```

---

## P1

#### Set up the VM for Kubernetes cluster

```bash
cd ~/mnt/p1
vagrant up
```

#### Validate paswordless SSH connection to both machines

```bash
vagrant ssh mcuturaSW
vagrant ssh mcuturaS
```

#### Verify correct configuration of the cluster from within the server VM

```bash
kubectl get nodes -o wide

ip a show eth1
```

#### Stop the cluster

```bash
vagrant halt
```

---

## P2


#### Set up the VM for K3s

```bash
cd ~/mnt/p2
vagrant up
```

#### SSH into the VM

```bash
vagrant ssh smargineS
```

### Instructions for Applications

#### Check if pods are up and running:

```bash
kubectl get pods -o wide -A
```

#### Apply resources for Applications

```bash
/vagrant/scripts/manage_apps.sh apply
```

#### List pods info:

```bash
kubectl get all
```

#### Test the internal Service by curling from within the VM:

```bash
# replace <CLUSTER-IP> with the CLUSTER-IP for the Service you want to test
curl http://<CLUSTER-IP>:80
```

#### Test the external Service by curling from within the VM:

```bash
curl -H "Host: app1.com" http://192.168.56.110   # for app1
curl -H "Host: app2.com" http://192.168.56.110   # for app2
curl http://192.168.56.110                       # for app3 (default) 
```

#### Delete resources for Applications

```bash
/vagrant/scripts/manage_apps.sh delete
```

---

## P3

### Install dependencies

```bash
~/mnt/p3/scripts/setup.sh
```

Relog/reboot to apply changes.

### Deploy the cluster

```bash
~/mnt/p3/scripts/deploy.sh
```

### Verify availability from main host

```bash
curl http://localhost:8888
```

### [Optional] Access ArgoCD UI

- Open the ArgoCD UI in the browser: `https://localhost:8080`  
- Accept the self-signed certificate.  
- Login with username: `admin` and the generated password.  

```bash
# Print the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo;
```

---

## Bonus

### Install requirements

```bash
~/mnt/bonus/scripts/setup.sh
```

If Docker was installed in this step (i.e. P3 was skipped) - relog/reboot to apply user group changes.

### Setup secrets

For simplicity, instead of a vault, we use .env file to store secrets.  
You can configure them manually and ensure to fill in all the required values in `credentials.env` before proceeding.  

```bash
cp ~/mnt/bonus/confs/credentials.env.example ~/mnt/bonus/confs/credentials.env
# Edit the file ~/mnt/bonus/confs/credentials.env and 
# fill in the required values,
# then save it.
```

OR Run a script that will do it for you.  

```bash
~/mnt/bonus/scripts/secretary.sh
```

### Deploy the cluster

```bash
~/mnt/bonus/scripts/deploy.sh
```

### Verify availability from main host

```bash
curl http://gitlab.127.0.0.1.nip.io:8081
```

### Create repository

```bash
~/mnt/bonus/scripts/create_repo.sh
```

Push the playground repository to the created GitLab repository.  

### Access services in the browser

#### GitLab

- Open the GitLab UI in the browser: `http://gitlab.127.0.0.1.nip.io:8081`  
- Login with username: `root` and the assigned password (you can find it in the .env file).  

#### ArgoCD

- Open the ArgoCD UI in the browser: `https://localhost:8080`  
- Accept the self-signed certificate.  
- Login with username: `admin` and the generated password.  

```bash
# Print the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo;
```


#### Playground app

- Open the app in the browser: `http://localhost:8888`  

---
