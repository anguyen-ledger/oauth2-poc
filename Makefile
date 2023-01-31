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

ssh:
	@echo Connecting to remote host with as sudo user
	ssh ubuntu@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 `

nginx-logs:
	@echo Displaying nginx logs
	ssh ubuntu@`cat ansible/inventory/hosts | grep -v "all" | cut -d " " -f1 ` tail -f /var/log/nginx/access.log

keycloak-get-token:
	@echo Get access token:
	@echo 
	@curl -s -k \
          -d "client_id=admin-cli" \
          -d "username=admin" \
          -d "password=admin" \
          -d "grant_type=password" \
          "https://keycloak-rp.localdomain.com/realms/master/protocol/openid-connect/token" | jq '.access_token' -r | tee /tmp/token

keycloak-create-realm: keycloak-get-token
	@echo Create new POC realm
	@echo
	@curl -s -k -XPOST \
          -H "Authorization: Bearer `cat /tmp/token`" \
          -H "Content-Type: application/json" \
          -d "@keycloak-poc-realm.json" \
	  https://keycloak-rp.localdomain.com/admin/realms

keycloak-create-client: keycloak-get-token
	@echo Create new POC realm
	@echo
	@curl -s -k -XPOST \
          -H "Authorization: Bearer `cat /tmp/token`" \
          -H "Content-Type: application/json" \
          -d "@keycloak-client.json" \
	  https://keycloak-rp.localdomain.com/admin/realms/POC/clients

keycloak-create-user: keycloak-get-token
	@echo Create new user in POC
	@echo
	@curl -s -k -XPOST \
          -H "Authorization: Bearer `cat /tmp/token`" \
          -H "Content-Type: application/json" \
	  --data-raw '{"firstName":"test","lastName":"test", "email":"test@test.com", "enabled":"true", "username":"test", "emailVerified": "true", "credentials": [{"type":"password","value":"test","temporary":false}]}' \
	  https://keycloak-rp.localdomain.com/admin/realms/POC/users

keycloak-get-client-secret: keycloak-get-client-id
	@echo GET client secret
	@echo
	@curl -s -k -XGET \
          -H "Authorization: Bearer `cat /tmp/token`" \
          -H "Content-Type: application/json" \
	  https://keycloak-rp.localdomain.com/admin/realms/POC/clients/`cat /tmp/clientId`/client-secret

keycloak-get-client-id: keycloak-get-token
	@echo GET client secret
	@echo
	@curl -s -k -XGET \
          -H "Authorization: Bearer `cat /tmp/token`" \
          -H "Content-Type: application/json" \
	  https://keycloak-rp.localdomain.com/admin/realms/POC/clients | \
	  jq -r '.[]| select(.clientId == "POC") | .id' | tee /tmp/clientId 
