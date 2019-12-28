BUILD=docker-compose -f build.docker-compose.yml -p windows-tomcat-ansible-deploy-build

# Deploy to AWS
.deploy: 
	docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run deploy

# Remove all the resources created by deploying
.destroy:
	docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run deploy destroy -auto-approve -input=false -force

# sh into the container - useful for running commands like import or plan
.deploy-sh:  
	docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint /bin/sh deploy

# get the output of the deployment as json (added the @ so we don't print the command we're running)
.deploy-output:  
	@docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy

.dev:
	$(BUILD) run -p 8080:8080 build gradle bootRun --no-daemon

.build:
	$(BUILD) run -p 8080:8080 build gradle build --no-daemon

# Test that the deployment work by pinging the server using ansible's winrm
.test:
	./update.sh -m win_ping
	./test.sh