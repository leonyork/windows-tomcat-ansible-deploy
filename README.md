# Deploy Tomcat services to a Windows server

Includes:
 - the [Terraform](https://www.terraform.io/) scripts to create the Windows server and security groups
 - the [Ansible](https://www.ansible.com/) configuration to connect

## Deploy

You'll need make, docker and docker-compose installed. You'll need an AWS account with the environment variables ```AWS_SECRET_KEY_ID``` and ```AWS_SECRET_ACCESS_KEY``` set.

Run ```make .deploy```

This will create a Windows AWS instance with a random password. You can then use 

### Destroy

Run ```make .destroy```

## Testing

Currently only works on bash

```make .test```



