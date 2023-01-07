output "HSM_POC_PUBLIC_IP" {
  value = module.oauth_poc_ec2.public_ip[0] 
}
