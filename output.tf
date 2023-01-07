output "HSM_POC_PUBLIC_IP" {
  value = module.hsm_controller_ec2.public_ip[0] 
}
