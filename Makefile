APP_BUILD=docker-compose -f app-build.docker-compose.yml -p windows-tomcat-ansible-deploy-build run
INFRA=docker-compose -f infra.docker-compose.yml -p windows-tomcat-ansible-deploy-infra run
INFRA_DEPLOYMENT_OUTPUT=$(INFRA) --entrypoint 'terraform output' deploy

HOST=$(shell $(INFRA_DEPLOYMENT_OUTPUT) public_ip)
PASSWORD=$(shell $(INFRA_DEPLOYMENT_OUTPUT) password)

APP_DEPLOY_DOCKER=docker-compose -f app-deploy.docker-compose.yml -p windows-tomcat-ansible-deploy-update
APP_DEPLOY=$(APP_DEPLOY_DOCKER) run -e HOST=$(HOST) -e PASSWORD=$(PASSWORD) deploy

# Deploy to AWS
.infra-deploy: 
	$(INFRA) deploy

# Remove all the resources created by deploying the infrastructure
.infra-destroy:
	$(INFRA) deploy destroy -auto-approve -input=false -force

# sh into the container - useful for running commands like import or plan
.infra-deploy-sh:  
	$(INFRA) --entrypoint /bin/sh deploy

# Wait for the deployment to complete - i.e. We can hit port 8080
.infra-deploy-wait:
	@docker run alpine:3.11.2 sh -c 'while ! nc -z $(HOST) 5986; do sleep 1; done; echo $(HOST):5986 available'  
	@docker run alpine:3.11.2 sh -c 'while ! nc -z $(HOST) 8080; do sleep 1; done; echo $(HOST):8080 available'

# Test that the deployment work by pinging the server using ansible's winrm and also checks that Tomcat was installed by hitting port 8080
.infra-deploy-test: .infra-deploy .infra-deploy-wait .app-deploy-build-image
	@$(APP_DEPLOY) ansible windows -m win_ping
	docker run --rm curlimages/curl:7.67.0 -L -m 10 -v http://$(HOST):8080/

# Run the application in dev mode
.app-dev:
	$(APP_BUILD) -p 8080:8080 gradle bootRun

# Clean the build files
.app-clean:
	$(APP_BUILD) gradle clean

# Build a war file
.app-build:
	$(APP_BUILD) gradle build

# Build the app-deploy docker image (useful for if you change the Dockerfile)
.app-deploy-build-image:
	$(APP_DEPLOY_DOCKER) build

# Update the server with the latest war file
.app-deploy: .app-build .app-deploy-build-image
	@$(APP_DEPLOY) ansible-playbook update.yml
	@echo Visit http://$(HOST):8080/ to view updated application

# Deploys the infrastructure and the application (including building the application). This also includes all tests.
.deploy: .infra-deploy-test .app-deploy

# Shortcut to destroy everything (just destroys the infrastructure)
.destroy: .infra-destroy