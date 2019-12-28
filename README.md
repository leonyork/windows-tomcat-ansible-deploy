# Deploy Tomcat services to a Windows server

[![Build Status](https://travis-ci.com/leonyork/windows-tomcat-ansible-deploy.svg?branch=master)](https://travis-ci.com/leonyork/windows-tomcat-ansible-deploy)

Includes:
 - the [Terraform](https://www.terraform.io/) scripts to create the Windows server and security groups
 - the [Ansible](https://www.ansible.com/) configuration to connect and deploy a simple app
 - a simple [Spring Boot](https://spring.io/projects/spring-boot) app that responds to requests with the date and time that it was built 

## Infrastructure

You'll need make, docker and docker-compose installed. You'll need an AWS account with the environment variables ```AWS_SECRET_KEY_ID``` and ```AWS_SECRET_ACCESS_KEY``` set.

### Deploy

```make .infra-deploy```

This will create a Windows AWS instance with a random password.

### Destroy

```make .infra-destroy```

### Testing

```make .infra-test```

## Application

Responds to http requests with the date and time it was built

### Develop

```make .app-dev```

### Build

```make .app-build```

### Deploy

```make .app-deploy```

## All together

Use ```make .deploy``` to create the infrastructure, build the app and deploy it.

Use ```make .destroy``` to destroy everything.



