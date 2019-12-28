BUILD=docker-compose -f build.docker-compose.yml -p windows-tomcat-ansible-deploy-build run
DEPLOY=docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run
DEPLOY_OUTPUT=$(DEPLOY) --entrypoint 'terraform output --json' deploy

HOST = $(shell $(DEPLOY_OUTPUT) | jq '.public_ip.value' -rj)
PASSWORD = $(shell $(DEPLOY_OUTPUT) | jq '.password.value' -rj)

UPDATE=docker-compose -f update.docker-compose.yml -p windows-tomcat-ansible-deploy-update run -e HOST=$(HOST) -e PASSWORD=$(PASSWORD) update 

# Deploy to AWS
.deploy: 
	$(DEPLOY) deploy

# Remove all the resources created by deploying
.destroy:
	$(DEPLOY) deploy destroy -auto-approve -input=false -force

# sh into the container - useful for running commands like import or plan
.deploy-sh:  
	$(DEPLOY) --entrypoint /bin/sh deploy

# Wait for the deployment to complete - i.e. We can hit port 8080
.deploy-wait:  
	@docker run alpine:3.11.2 sh -c 'while ! nc -z $(HOST) 8080; do sleep 1; done; echo $(HOST):8080 available'

# Run the application in dev mode
.dev:
	$(BUILD) -p 8080:8080 gradle bootRun

.clean:
	$(BUILD) gradle clean

# Build a war file
.build:
	$(BUILD) gradle build

# Update the server with the latest war file
.update:
	@$(UPDATE) ansible-playbook update.yml

# Test that the deployment work by pinging the server using ansible's winrm and also checks that Tomcat was installed by hitting port 8080
.deploy-test:
	@$(UPDATE) ansible windows -m win_ping
	docker run --rm curlimages/curl:7.67.0 -L -m 10 -v http://$(HOST):8080/