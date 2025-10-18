output "server_id" {
  description = "The ID of the Hetzner server"
  value       = hcloud_server.main_server.id
}

output "server_public_ip" {
  description = "The public IP address of the server"
  value       = hcloud_server.main_server.ipv4_address
}

output "server_private_ip" {
  description = "Private IP address of the server"
  value       = null # Hetzner servers don't have private IPs by default
}

output "server_ipv6" {
  description = "IPv6 address of the server"
  value       = hcloud_server.main_server.ipv6_address
}

output "server_name" {
  description = "Name of the server"
  value       = hcloud_server.main_server.name
}

output "server_status" {
  description = "Status of the server"
  value       = hcloud_server.main_server.status
}

output "server_datacenter" {
  description = "Datacenter location of the server"
  value       = hcloud_server.main_server.datacenter
}

output "firewall_id" {
  description = "The ID of the Hetzner firewall"
  value       = hcloud_firewall.server_firewall.id
}

output "ssh_key_id" {
  description = "The ID of the SSH key"
  value       = hcloud_ssh_key.server_ssh_key.id
}

output "ssh_connection_string" {
  description = "Full SSH connection command"
  value       = "ssh -i ~/.ssh/deploy_rsa root@${hcloud_server.main_server.ipv4_address}"
}

output "docker_swarm_enabled" {
  description = "Whether Docker Swarm was initialized"
  value       = var.enable_docker_swarm
}

output "server_labels" {
  description = "Labels applied to the server"
  value       = hcloud_server.main_server.labels
}
