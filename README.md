# Distributed Cluster with Docker Swarm, Ansible, and Vagrant

This project was developed as part of a university course in **Virtualization and Cloud Computing**, [GitHub course organization](https://github.com/VCC-course). 

It implements a **3-node cluster** environment using Vagrant, Docker Swarm, and Ansible, deploying several production-grade services to simulate a real-world cloud infrastructure.

## Overview

The goal was to automate the deployment of a distributed system for service orchestration and monitoring using open-source tools. The infrastructure includes:

### Core Services

| Service        | Purpose                                      |
| -------------- | -------------------------------------------- |
| **Forgejo**    | Self-hosted Git service (version control)    |
| **Grafana**    | Visualization dashboards for metrics/logs    |
| **Prometheus** | Metrics scraping and monitoring              |
| **Loki**       | Log aggregation                              |
| **Dex**        | Single Sign-On (SSO) provider                |
| **Traefik**    | Reverse proxy and ingress controller         |
| **PostgreSQL** | Relational database used by several services |

### Additional Tools (Optional, Not Required for Course)

| Service       | Purpose                                         |
| ------------- | ----------------------------------------------- |
| **Portainer** | GUI for managing Docker containers and services |
| **PgAdmin**   | GUI for managing PostgreSQL database            |
| **Homer**     | Dashboard for quick service navigation          |

To enable these optional services, open the [`main.yml`](roles/swarm-services/defaults/main.yml) file and **uncomment** the `# utilities` section.

---

## Technologies Used

* **Vagrant**: Used to provision three virtual machines (nodes).
* **Ansible**: Automates the configuration and deployment of services.
* **Docker Swarm**: Manages service orchestration and distribution across nodes.
* **NFS**: Used for shared storage between nodes.
* **Traefik**: Handles HTTPS termination via a self-signed certificate.
* **Private Docker Registry**: Stores custom local images.

---

## Configuration & Setup

### 1. Configure Your Environment

Before running the setup, you need to configure your own `config.yml`:

* Edit and complete the [`config_template.yml`](config_template.yml) file, then rename it to `config.yml`.

#### Configuration Details:

* In the `os` field:

  * Set `1` for Linux/Mac.
  * Set `0` for Windows.

* In the `key_file_path_ubuntu` field:

  * Leave it empty if you're using Linux/Mac.
  * For Windows, this field is essential as it specifies the path to the SSH key used to connect to the Ubuntu virtual machine.

* In the `provider` field:

  * List all the possible providers you can use for Vagrant. Some common options are:

    * `virtualbox`
    * `vmware_desktop`
    * `vmware_workstation`
    * `vmware_fusion`
    * `libvirt`

For Windows users: you must use an Ubuntu virtual machine to run the project. This is why the `key_file_path_ubuntu` is crucial, as it ensures that the SSH key is shared properly to allow connection to the VM.

### 2. Launch Virtual Machines

```bash
vagrant up
```

This will create and configure the three VM nodes using VMware or your configured provider.

### 3. Set Up Python Environment

```bash
make python-setup
```

Installs required Python dependencies.

### 4. Deploy the Full Infrastructure

```bash
make setup-all
```

This command runs all necessary Ansible playbooks to install Docker, configure Swarm, deploy services, and set up the environment.

### 5. DNS Resolution with Traefik

For the infrastructure to work correctly with Traefik resolving DNS, you need to add the following entries to your system's `hosts` file:

* **For Mac/Linux**: Edit the `/etc/hosts` file.
* **For Windows**: Modify the `C:\Windows\System32\drivers\etc\hosts` file.

Add the following line to the `hosts` file:

```
192.168.88.10 home.vcc.internal prom.vcc.internal mon.vcc.internal auth.vcc.internal git.vcc.internal pgadmin.vcc.internal portainer.vcc.internal
```

This ensures that Traefik can resolve the internal domain names for each of the services within your infrastructure.

---

## Notes

### Infrastructure
* All services are containerized and orchestrated across the three-node Swarm cluster.
* Shared volumes are mounted using NFS to maintain data consistency.
* The infrastructure is modular and can be extended with new services or features.

### Security

* A **self-signed TLS certificate** is used to secure communication.
* Services are routed and exposed securely via **Traefik**.
* **Dex** enables single sign-on (SSO) across services supporting OAuth2.

### Custom Docker Images

* Some services rely on custom-built Docker images, which are stored in a **private Docker registry** to enable portability and speed up deployment.

