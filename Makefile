HOST = $(shell docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy | jq '.public_ip.value' -rj)
PASSWORD = $(shell docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy | jq '.password.value' -rj)
BUILD=docker-compose -f build.docker-compose.yml -p windows-tomcat-ansible-deploy-build
DEPLOY=docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy
UPDATE=docker-compose -f update.docker-compose.yml run -e HOST=$(HOST) -e PASSWORD=$(PASSWORD) update 

# Deploy to AWS
.deploy: 
	$(DEPLOY) run deploy

# Remove all the resources created by deploying
.destroy:
	$(DEPLOY) run deploy destroy -auto-approve -input=false -force

# sh into the container - useful for running commands like import or plan
.deploy-sh:  
	$(DEPLOY) run --entrypoint /bin/sh deploy

# get the output of the deployment as json (added the @ so we don't print the command we're running)
.deploy-output:  
	@$(DEPLOY) run --entrypoint 'terraform output --json' deploy

.dev:
	$(BUILD) run -p 8080:8080 build gradle bootRun --no-daemon

.clean:
	$(BUILD) run build gradle clean --no-daemon

.build:
	$(BUILD) run build gradle build --no-daemon

.update:
	$(UPDATE) ansible-playbook update.yml

# Test that the deployment work by pinging the server using ansible's winrm and also checks that Tomcat was installed by hitting port 8080
.deploy-test:
	@$(UPDATE) ansible windows -m win_ping
	docker run --rm curlimages/curl:7.67.0 -L -m 10 -v http://$(HOST):8080/