# Troubleshooting Guide

Solutions to common issues when deploying and managing Docker Swarm infrastructure.

## Table of Contents

- [Configuration Issues](#configuration-issues)
- [Terraform Issues](#terraform-issues)
- [Deployment Issues](#deployment-issues)
- [SSL/TLS Issues](#ssltls-issues)
- [DNS Issues](#dns-issues)
- [Docker Swarm Issues](#docker-swarm-issues)
- [Service Issues](#service-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)

## Configuration Issues

### Validation Fails - Missing Required Fields

**Error**: `Configuration has X errors`

**Solution**:
```bash
# Run validation to see specific errors
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars

# Fix reported errors
nano terraform/terraform.dev.tfvars

# Re-validate
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
```

**Common Missing Fields**:
- `hetzner_token` - Get from Hetzner Cloud Console
- `hetzner_dns_token` - Get from Hetzner DNS Console
- `hetzner_dns_zone_id` - Get from DNS zone URL
- `ssh_public_key` - Run `./scripts/utils/generate-ssh-keys.sh`
- `admin_password_hash` - Run `./scripts/utils/generate-password.sh`

### Invalid Domain Format

**Error**: `Invalid domain format: ...`

**Incorrect**:
```hcl
domain_name = "https://example.com"  # Has protocol
domain_name = "example.com/"         # Has trailing slash
domain_name = "EXAMPLE.COM"          # Uppercase
```

**Correct**:
```hcl
domain_name = "example.com"
domain_name = "dev.example.com"
```

### Invalid Email Format

**Error**: `Invalid email format: ...`

**Correct**:
```hcl
traefik_acme_email = "admin@example.com"
```

### SSH Key Format Invalid

**Error**: `SSH public key does not start with ssh-`

**Solution**:
```bash
# Check your key
cat ~/.ssh/deploy_ed25519.pub

# Should start with ssh-ed25519 or ssh-rsa
# If not, regenerate:
./scripts/utils/generate-ssh-keys.sh deploy ed25519
```

### Password Hash Format Invalid

**Error**: `Admin password hash is not in bcrypt format`

**Solution**:
```bash
# Generate proper hash
./scripts/utils/generate-password.sh admin

# Copy the output (includes "admin:$2y$...")
# Paste into your config file
```

## Terraform Issues

### terraform init Fails

**Error**: `Failed to install provider`

**Solution 1** - Clear and reinitialize:
```bash
cd terraform/
rm -rf .terraform/ .terraform.lock.hcl
terraform init
```

**Solution 2** - Network issue:
```bash
# Check internet connectivity
ping terraform.io

# Use proxy if needed
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
terraform init
```

### terraform plan Shows Unexpected Changes

**Error**: Plan shows resources being destroyed/recreated

**Debug**:
```bash
# Check what changed
terraform plan -var-file="terraform.dev.tfvars" -out=plan.out
terraform show plan.out

# If incorrect, don't apply!
```

**Common Causes**:
- Server type changed (recreates server)
- Location changed (recreates server)
- SSH key changed (recreates server)

**Solution**: Verify configuration changes are intentional

### State Lock Error

**Error**: `Error acquiring the state lock`

**Cause**: Previous terraform command crashed or still running

**Solution**:
```bash
# Check for running terraform processes
ps aux | grep terraform

# Kill if stuck
kill -9 <PID>

# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### State Out of Sync

**Error**: `Resource not found in state`

**Solution**:
```bash
# Refresh state
terraform refresh -var-file="terraform.dev.tfvars"

# Or import missing resource
terraform import hcloud_server.main_server <SERVER_ID>
```

## Deployment Issues

### Server Creation Fails

**Error**: `Error creating server`

**Possible Causes**:

1. **Invalid API Token**
   ```bash
   # Test token
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://api.hetzner.cloud/v1/servers
   ```

2. **Server Type Not Available**
   ```bash
   # Check available types
   curl https://api.hetzner.cloud/v1/server_types
   
   # Change server_type in config
   ```

3. **Resource Limit Reached**
   - Check Hetzner Cloud Console for limits
   - Request limit increase if needed

4. **Location Not Available**
   ```hcl
   # Try different location
   location = "fsn1"  # Instead of nbg1
   ```

### DNS Record Creation Fails

**Error**: `Error creating DNS record`

**Debug**:
```bash
# Verify zone exists
curl -H "Auth-API-Token: YOUR_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/zones

# Check zone ID
curl -H "Auth-API-Token: YOUR_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/zones/YOUR_ZONE_ID
```

**Solutions**:
1. Verify `hetzner_dns_zone_id` is correct
2. Verify DNS token has write permissions
3. Ensure zone is for correct domain

### Firewall Rule Creation Fails

**Error**: `Error creating firewall`

**Solution**:
```bash
# Check existing firewalls
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.hetzner.cloud/v1/firewalls

# Delete old firewall if exists
# Then re-run terraform apply
```

## SSL/TLS Issues

### Certificates Not Generating

**Symptoms**: Services accessible via HTTP but not HTTPS

**Wait First**: Let's Encrypt needs 5-10 minutes

**Debug**:
```bash
# SSH to server
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>

# Check Traefik logs
docker service logs traefik | grep -i acme | tail -50

# Check certificate store
ls -la /opt/traefik/acme.json
```

**Common Causes**:

1. **DNS Not Propagated**
   ```bash
   # Check DNS from external source
   dig +short @8.8.8.8 admin.example.com
   
   # Should return server IP
   # If not, wait 5-10 more minutes
   ```

2. **Port 80 Blocked**
   ```bash
   # Test from external machine
   curl -I http://admin.example.com
   
   # Should get redirect to HTTPS
   ```

3. **Invalid Email**
   - Verify `traefik_acme_email` is valid email address
   - Let's Encrypt will reject invalid emails

4. **Rate Limit Hit**
   - Let's Encrypt has rate limits (5 per week for same domain)
   - Use staging environment for testing
   - Wait 7 days for rate limit reset

**Solution for Rate Limit**:
```bash
# Edit deploy-services.sh to use staging
# Change:
--certificatesresolvers.letsencrypt.acme.server=https://acme-v02.api.letsencrypt.org/directory
# To:
--certificatesresolvers.letsencrypt.acme.server=https://acme-staging-v02.api.letsencrypt.org/directory
```

### Certificate Expired or Invalid

**Error**: Browser shows certificate error

**Solution**:
```bash
# SSH to server
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>

# Remove old certificates
rm /opt/traefik/acme.json

# Restart Traefik
docker service update --force traefik

# Wait 10 minutes for new certificates
```

### Mixed Content Warnings

**Cause**: Loading HTTP resources on HTTPS page

**Solution**:
- Update all resource URLs to use HTTPS
- Or use protocol-relative URLs (`//example.com/resource`)

## DNS Issues

### DNS Not Resolving

**Symptoms**: `dig` returns no results

**Debug**:
```bash
# Check DNS
dig +short admin.example.com

# Check from different DNS server
dig +short @8.8.8.8 admin.example.com
dig +short @1.1.1.1 admin.example.com

# Check Hetzner DNS
curl -H "Auth-API-Token: YOUR_DNS_TOKEN" \
  https://dns.hetzner.com/api/v1/records?zone_id=YOUR_ZONE_ID
```

**Solutions**:
1. **Wait for propagation** (up to 48 hours, usually 5-10 minutes)
2. **Verify zone configuration** in Hetzner DNS
3. **Check nameservers**:
   ```bash
   dig NS example.com
   # Should return Hetzner nameservers
   ```

### Wrong IP Address Returned

**Debug**:
```bash
# Get expected IP
./scripts/deploy-env.sh dev output | grep server_public_ip

# Get actual DNS response
dig +short admin.example.com

# Should match
```

**Solution**:
```bash
# Refresh Terraform state
cd terraform/
terraform refresh -var-file="terraform.dev.tfvars"

# Re-apply
terraform apply -var-file="terraform.dev.tfvars"
```

### Subdomain Not Working

**Error**: Main domain works but subdomains don't

**Check**:
```bash
# Verify DNS records
dig +short example.com          # Should work
dig +short admin.example.com    # Should work
dig +short www.example.com      # Should work (if configured)
```

**Solution**: Ensure all CNAME/A records are created in Hetzner DNS

## Docker Swarm Issues

### Swarm Not Initialized

**Symptoms**: Docker commands fail with "This node is not a swarm manager"

**Debug**:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
docker node ls
```

**Solution**:
```bash
# Re-initialize swarm
docker swarm init --advertise-addr <SERVER_IP>

# Recreate networks
docker network create --driver overlay traefik-public
docker network create --driver overlay backend
```

### Service Not Starting

**Symptoms**: `docker service ls` shows 0/1 replicas

**Debug**:
```bash
# Check service status
docker service ps <service-name>

# Check service logs
docker service logs <service-name>

# Check events
docker events --since 10m
```

**Common Causes**:

1. **Image Pull Failure**
   ```bash
   # Manual pull to test
   docker pull traefik:v2.10
   ```

2. **Resource Constraints**
   ```bash
   # Check node resources
   docker node inspect self --format '{{.Description.Resources}}'
   
   # Solution: Use larger server type
   ```

3. **Network Issues**
   ```bash
   # Recreate network
   docker network rm traefik-public
   docker network create --driver overlay traefik-public
   ```

### Can't Connect to Services

**Debug**:
```bash
# Check service endpoints
docker service inspect traefik --format '{{.Endpoint}}'

# Check network connectivity
docker run --rm --network traefik-public alpine ping traefik
```

## Service Issues

### Traefik Dashboard Not Accessible

**Symptoms**: 404 or connection refused

**Debug**:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>

# Check Traefik status
docker service ls | grep traefik
docker service logs traefik | tail -50

# Check if listening
netstat -tlnp | grep 80
netstat -tlnp | grep 443
```

**Solutions**:
1. **Wait for SSL certificates** (5-10 minutes)
2. **Check firewall rules**:
   ```bash
   # Hetzner firewall should allow 80/443
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://api.hetzner.cloud/v1/firewalls
   ```
3. **Verify DNS** points to server

### Swarmpit Won't Load

**Symptoms**: Connection timeout or 502 error

**Debug**:
```bash
# Check Swarmpit status
docker service ps swarmpit

# Check logs
docker service logs swarmpit
```

**Common Issues**:
1. **Database not ready**
   - Wait 2-3 minutes for DB initialization
2. **Memory constraints**
   - Use larger server type (min CX22)

### Dozzle Shows No Logs

**Symptoms**: Dozzle loads but shows no containers

**Debug**:
```bash
# Check Dozzle has Docker socket access
docker service inspect dozzle

# Verify socket mount
docker service inspect dozzle --format '{{.Spec.TaskTemplate.ContainerSpec.Mounts}}'
```

**Solution**:
- Verify Dozzle is on same node as containers
- Check Docker socket permissions

## Network Issues

### Can't Access Services from Internet

**Debug**:
```bash
# From external machine
curl -I https://admin.example.com

# Check from server itself
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
curl -I http://localhost
```

**Checklist**:
- [ ] DNS resolves to correct IP
- [ ] Ports 80/443 open in firewall
- [ ] Traefik service running
- [ ] SSL certificates issued

### Can't SSH to Server

**Error**: `Permission denied (publickey)`

**Solutions**:
1. **Check SSH key**:
   ```bash
   chmod 600 ~/.ssh/deploy_ed25519
   ssh -i ~/.ssh/deploy_ed25519 -v root@<SERVER_IP>
   ```

2. **Wrong key**:
   - Verify public key in Hetzner matches private key locally
   
3. **Server not accessible**:
   ```bash
   ping <SERVER_IP>
   # If fails, check server is running in Hetzner Console
   ```

### Internal Service Communication Fails

**Symptoms**: Services can't talk to each other

**Debug**:
```bash
# Check overlay network
docker network ls | grep overlay

# Inspect network
docker network inspect traefik-public

# Test connectivity
docker run --rm --network traefik-public alpine ping <service-name>
```

**Solution**:
```bash
# Recreate overlay networks
docker network rm traefik-public backend
docker network create --driver overlay traefik-public
docker network create --driver overlay backend

# Update services
docker service update --network-add traefik-public traefik
```

## Performance Issues

### Slow Response Times

**Debug**:
```bash
# Check server load
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
top
htop

# Check memory
free -h

# Check disk
df -h
```

**Solutions**:
1. **Upgrade server type**:
   ```hcl
   server_type = "cx32"  # From cx22
   ```

2. **Check resource limits**:
   ```bash
   docker stats
   ```

3. **Optimize services**:
   - Reduce log verbosity
   - Adjust resource limits
   - Add caching

### High Memory Usage

**Debug**:
```bash
# Check memory per service
docker stats --no-stream

# Check system memory
free -h
```

**Solution**:
```bash
# Adjust service memory limits in deploy-services.sh
--limit-memory="256M"
--reserve-memory="64M"

# Or upgrade server
```

### Disk Space Full

**Debug**:
```bash
df -h
du -sh /var/lib/docker/*
```

**Solution**:
```bash
# Clean old images
docker image prune -a

# Clean volumes
docker volume prune

# Clean system
docker system prune -a --volumes
```

## Getting More Help

### Enable Debug Logging

**Terraform**:
```bash
export TF_LOG=DEBUG
terraform apply -var-file="terraform.dev.tfvars"
```

**Traefik**:
```bash
# Add to deploy-services.sh
--log.level=DEBUG
```

### Collect Diagnostic Information

```bash
# System info
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
uname -a
docker version
docker info

# Service status
docker service ls
docker service ps traefik swarmpit dozzle

# Logs
docker service logs --tail 100 traefik > traefik.log
docker service logs --tail 100 swarmpit > swarmpit.log
docker service logs --tail 100 dozzle > dozzle.log

# Network
docker network ls
ip addr show

# Download logs
scp -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>:*.log .
```

### Contact Support

When opening an issue, include:
1. Error message (exact text)
2. Configuration (sanitized, no secrets!)
3. Terraform version: `terraform version`
4. Steps to reproduce
5. Logs from diagnostic collection above

## Prevention Tips

1. **Always validate before deploy**:
   ```bash
   ./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
   ```

2. **Test in dev first**:
   - Never test in production
   - Use dev environment for experiments

3. **Keep backups**:
   - Export important data regularly
   - Document configuration
   - Save Terraform state

4. **Monitor proactively**:
   - Check logs regularly
   - Monitor resource usage
   - Set up alerts

5. **Stay updated**:
   - Update Terraform regularly
   - Update Docker images
   - Review Hetzner announcements

---

**Still stuck?** Open a [GitHub Issue](https://github.com/YOUR_USERNAME/infrastructure/issues) with diagnostic information.
