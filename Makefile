HSM_TARGET=hsm-pa2-h18
LOCAL_PORT=8888

taint:
	@echo Tainting ec2 resource and null_resource
	terraform1.2.6 taint "module.hsm_controller_ec2.aws_instance.this[0]"
	terraform1.2.6 taint "null_resource.ansible_inventory"

tf-apply:
	@echo Creating resources
	terraform1.2.6 apply --auto-approve

re-build: taint tf-apply
	@echo Re-build terraform platform

bootstrap:
	@echo Bootstraping instance \"`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `\"i
	@echo "\n"
	cd ansible; ansible-playbook -i inventory/hosts bootstrap.yaml

set-tunnel-443:
	@echo Open tunnel with the controller on port $(LOCAL_PORT) to reach Nginx on HTTPS
	@echo This tunnel used a retricted user "test" 
	@echo "\n"
	ssh -N -L $(LOCAL_PORT):127.0.0.1:443 test@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `

set-tunnel-80:
	@echo Open tunnel with the controller on port $(LOCAL_PORT) to reach Nginx on HTTP
	@echo This tunnel used a retricted user "test" 
	@echo This should not work as we only allow HTTPS to be forwarded 
	@echo PermitOpen 127.0.0.1:443 
	@echo "\n"
	ssh -N -L $(LOCAL_PORT):127.0.0.1:80 test@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `

check-ssh-restricted:
	@echo Check that ssh shell is not allowed from restricted user
	ssh test@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `
	
ssh:
	@echo Connecting to remote host with as sudo user
	ssh ubuntu@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `

nginx-logs:
	@echo Displaying nginx logs
	ssh ubuntu@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 ` tail -f /var/log/nginx/access.log

api-status:
	@echo Performning /status on $(HSM_TARGET)
	curl -s -u test -k https://localhost:$(LOCAL_PORT)/$(HSM_TARGET)/status | jq '.output' -r

api-reset:
	@echo Performing /reset on $(HSM_TARGET)
	curl -s -u test -k -XPUT https://localhost:$(LOCAL_PORT)/$(HSM_TARGET)/reset | jq '.output' -r
