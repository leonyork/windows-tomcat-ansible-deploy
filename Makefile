DOCKER_COMPOSE_APP_BUILD=docker-compose -f app-build.docker-compose.yml
DOCKER_COMPOSE_APP_DEPLOY=docker-compose -f app-deploy.docker-compose.yml
DOCKER_COMPOSE_INFRA=docker-compose -f infra.docker-compose.yml

APP_BUILD=$(DOCKER_COMPOSE_APP_BUILD) -p windows-tomcat-ansible-deploy-build run
INFRA=$(DOCKER_COMPOSE_INFRA) -p windows-tomcat-ansible-deploy-infra run
# Added the sed as we need to escape backslashes - i.e. \ becomes \\. Due to the number of layers of escaping we end up with lots of backslashes!
INFRA_DEPLOYMENT_OUTPUT=$(INFRA) --entrypoint 'terraform output' deploy

HOST=$(shell $(INFRA_DEPLOYMENT_OUTPUT) public_ip)
PASSWORD=$(shell $(INFRA_DEPLOYMENT_OUTPUT) password)
TOMCAT_LOCATION=$(shell $(INFRA_DEPLOYMENT_OUTPUT) tomcat_location)
TOMCAT_EXECUTABLE=$(shell $(INFRA_DEPLOYMENT_OUTPUT) tomcat_executable)
# Need to pass the result of this gradle task through head to get the first line (relies on gradle task doing a println not print).
# If we just print from gradle then the following characters are added - \u001b[0m\u001b[?12l\u001b[?25h
# So to get round this we do println in gradle and then pipe the result through head. 
BUILD_ARTEFACT=$(shell $(APP_BUILD) --entrypoint sh gradle -c 'gradle printProjectAndVersion --no-daemon --console=plain -q | head -n 1')

APP_DEPLOY_DOCKER=$(DOCKER_COMPOSE_APP_DEPLOY) -p windows-tomcat-ansible-deploy-update
APP_DEPLOY=$(APP_DEPLOY_DOCKER) run -e HOST=$(HOST) -e PASSWORD=$(PASSWORD) deploy

# Pull the Docker images required for infra
.infra-pull:
	@$(DOCKER_COMPOSE_INFRA) pull --quiet

# Pull the Docker images required for the app build
.app-build-pull:
	@$(DOCKER_COMPOSE_APP_BUILD) pull --quiet

# Build the app-deploy docker image (useful for if you change the Dockerfile)
.app-deploy-build-image:
	@$(APP_DEPLOY_DOCKER) build

# Deploy to AWS
.infra-deploy: .infra-pull
	$(INFRA) deploy

# Remove all the resources created by deploying the infrastructure
.infra-destroy: .infra-pull
	$(INFRA) deploy destroy -auto-approve -input=false -force

# sh into the container - useful for running commands like import or plan
.infra-deploy-sh: .infra-pull  
	$(INFRA) --entrypoint /bin/sh deploy

# Added for re-use across multiple ports - see below
.infra-deploy-wait-%:
	@echo Waiting for $(HOST):$* to become available...
	@docker run alpine:3.11.2 sh -c 'while ! nc -z $(HOST) $*; do sleep 1; done; echo $(HOST):$* available'  

# Wait for the deployment to complete - i.e. We can hit ports 5986 and 8080
# Added the ; to ensure that we don't run .infra-%
.infra-deploy-wait: .infra-deploy-wait-5986 .infra-deploy-wait-8080 ;

# Test that the deployment work by pinging the server using ansible's winrm and also checks that Tomcat was installed by hitting port 8080
.infra-deploy-test: .infra-deploy .infra-deploy-wait .app-deploy-build-image
	$(APP_DEPLOY) ansible windows -m win_ping
	docker run --rm curlimages/curl:7.67.0 -L -m 10 -v http://$(HOST):8080/

# Get the outputs from the infra deployment (e.g. make .infra-password gets the password to logon to the server)
.infra-%: .infra-pull
	@$(INFRA_DEPLOYMENT_OUTPUT) $*

# Run the application in dev mode.
.app-bootRun: .app-build-pull
	$(APP_BUILD) -p 8080:8080 gradle bootRun

# Perform a gradle task for the app (e.g. make .app-build runs gradle build). Runs with the -q (quiet) flag so output can be used
.app-%: .app-build-pull
	@$(APP_BUILD) gradle $* -q

# Update the server with the latest war file
.app-deploy: .app-build .app-deploy-build-image
	$(APP_DEPLOY) ansible-playbook app-deploy.playbook.yml --extra-vars "web_archive=$(BUILD_ARTEFACT) tomcat_location=$(subst \,\\\\,$(TOMCAT_LOCATION)) tomcat_executable=$(TOMCAT_EXECUTABLE)"
	@echo Visit http://$(HOST):8080/ to view updated application

# Deploys the infrastructure and the application (including building the application). This also includes all tests.
.deploy: .infra-deploy-test .app-deploy

# Shortcut to destroy everything (i.e. the infrastructure)
.destroy: .infra-destroy