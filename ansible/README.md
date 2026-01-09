# Ansible deployment 

This repo includes an Ansible role that deploys and runs `ad-join-script.sh` in a non-interactive way by passing all inputs as variables.

## Files

- `ansible/site.yml`: example playbook using the role
- `ansible/roles/ad_join`: role that copies and runs the script

## Variables

Required:

- `ad_join_hostname`: short hostname (without domain)
- `ad_join_domain_name`: AD domain (e.g. `corp.example.com`)
- `ad_join_admin_user`: account used to join the domain
- `ad_join_admin_password`: password for `ad_join_admin_user`
- `ad_join_dns_servers`: DNS server IPs used to validate domain resolution (list preferred; also accepts a comma-separated string)
- `ad_join_dns_server`: single DNS server IP (backward compatible)
- `ad_join_ad_group`: AD group to grant sudo access (written to `/etc/sudoers`)

Optional:

- `ad_join_force` (default: `false`): run even if `realm list` already shows the domain
- `ad_join_run` (default: `true`): set to `false` to only deploy the script

## Semaphore setup notes

- Point Semaphore to the playbook at `ansible/site.yml`.
- Define the variables above in the task template (use a secret variable for `ad_join_admin_password`).

## Run (example)

```bash
ansible-playbook -i inventory.ini ansible/site.yml \
  -e ad_join_hostname=ubuntuhost01 \
  -e ad_join_domain_name=corp.example.com \
  -e ad_join_admin_user=JoinUser \
  -e ad_join_admin_password='***' \
  -e 'ad_join_dns_servers=["192.0.2.53","192.0.2.54"]' \
  -e ad_join_ad_group='LinuxAdmins'
```

## Important behavior

- The script attempts to configure DNS via `systemd-resolved` first, then falls back to writing `/etc/resolv.conf`. If DNS is managed elsewhere, you may need to adapt DNS configuration for your environment.
- The role runs the join step only when the host is not already joined (unless `ad_join_force: true`).
