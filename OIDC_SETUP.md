# OpenSearch OIDC Authentication Setup

This document describes the complete OIDC (OpenID Connect) authentication setup for OpenSearch and OpenSearch Dashboards.

## Overview

The OIDC setup allows users to authenticate using external identity providers (IdP) like GitLab, Google, Azure AD, etc. This provides a more secure and user-friendly authentication experience.

## Configuration Files Modified

### 1. Main Configuration (`inventories/opensearch/group_vars/all/all.yml`)

The following OIDC settings have been configured:

```yaml
# Auth type: 'internal' or 'oidc' (OpenID). Default: internal
auth_type: oidc

# OIDC settings
oidc:
  name: "GitLab"
  logo: "gitlab"
  description: "Authenticate via IdP"
  # OpenID server URI
  connect_url: https://gitlab.com/.well-known/openid-configuration
  # The JWT token field that contains the user name
  subject_key: preferred_username
  # the JWT token field that contains a list of user roles
  roles_key: roles
  # Scopes
  scopes: "openid profile email"
  # The address of Dashboards to redirect the user to after successful authentication
  dashboards_url: https://kibana.miriyev.ai
  # IdP client ID
  client_id: "{{ lookup('bitwarden.secrets.lookup', '0e6d8c47-1672-48dc-af58-b2de009c2b9a') }}"
  # IdP client secret
  client_secret: "{{ lookup('bitwarden.secrets.lookup', '02c00ca3-7d70-45f3-aa72-b2de009c478f') }}"
  # Additional OIDC settings
  enable_ssl: false
  verify_hostnames: false
  # Default role for OIDC users (can be overridden by roles_key)
  default_role: "oidc_readonly"

# Enable custom security configurations
copy_custom_security_configs: true
```

### 2. Security Configuration (`roles/linux/opensearch/templates/security_plugin_conf.yml`)

The security configuration has been updated to include:

- OIDC authentication domain
- Proper authorization backend for OIDC
- SSL and hostname verification settings

### 3. Dashboards Configuration (`roles/linux/dashboards/templates/opensearch_dashboards.yml`)

The dashboards configuration includes:

- Multiple authentication methods (Basic Auth + OIDC)
- Custom branding for both authentication methods
- OIDC-specific settings

### 4. Role Mappings (`files/roles_mapping.yml`)

Added OIDC-specific role mappings:

- `oidc_admin`: Maps to `all_access` role
- `oidc_readonly`: Maps to `readall` role  
- `oidc_security_analyst`: Maps to `indexes_security_search_full_access` role
- `oidc_web_analyst`: Maps to `indexes_web_search_full_access` role

### 5. Role Definitions (`files/roles.yml`)

Added OIDC-specific roles with appropriate permissions:

- `oidc_admin`: Full access to all indices and tenants
- `oidc_readonly`: Read-only access to all indices
- `oidc_security_analyst`: Access to security-related indices
- `oidc_web_analyst`: Access to web-related indices

## OIDC Role Assignment

Users can be assigned roles in two ways:

### 1. Via JWT Token Claims

If your IdP supports custom claims, you can include a `roles` claim in the JWT token with values like:
- `opensearch_admin` → Maps to `oidc_admin` role
- `opensearch_readonly` → Maps to `oidc_readonly` role
- `opensearch_security_read` → Maps to `oidc_security_analyst` role
- `opensearch_web_read` → Maps to `oidc_web_analyst` role

### 2. Default Role Assignment

Users without specific role claims will be assigned the `oidc_readonly` role by default.

## Brand Images

The setup includes support for custom brand images:

- `files/basicauth.png`: Image for basic authentication login
- `files/gitlab.png`: Image for GitLab OIDC login

These images are automatically copied to the dashboards configuration directory during deployment.

## Deployment

To deploy the OIDC-enabled OpenSearch cluster:

1. Ensure your IdP (GitLab) is configured with the correct redirect URI: `https://kibana.miriyev.ai`
2. Update the `client_id` and `client_secret` in your Bitwarden vault
3. Run the Ansible playbook:

```bash
ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml
```

## Testing OIDC Authentication

1. Navigate to `https://kibana.miriyev.ai`
2. You should see both "Basic Authentication" and "Log in with GitLab" options
3. Click "Log in with GitLab" to test OIDC authentication
4. After successful authentication, you should be redirected back to Dashboards

## Troubleshooting

### Common Issues

1. **Redirect URI Mismatch**: Ensure the redirect URI in your IdP matches `https://kibana.miriyev.ai`

2. **SSL Certificate Issues**: If using self-signed certificates, ensure `verify_hostnames: false` is set

3. **Role Assignment**: Check that users have the correct roles assigned in your IdP or that the default role is appropriate

4. **Brand Images**: Ensure the brand images exist in the `files/` directory

### Logs

Check the following logs for troubleshooting:

- OpenSearch logs: `/var/log/opensearch/`
- Dashboards logs: `/var/log/opensearch-dashboards/`
- System logs: `journalctl -u opensearch` and `journalctl -u dashboards`

## Security Considerations

1. **Client Secret**: Store the client secret securely (using Bitwarden as configured)
2. **SSL/TLS**: Use proper SSL certificates in production
3. **Role Permissions**: Review and adjust role permissions based on your security requirements
4. **Network Security**: Ensure proper network segmentation and firewall rules

## Customization

### Adding New Roles

1. Add the role definition to `files/roles.yml`
2. Add the role mapping to `files/roles_mapping.yml`
3. Update your IdP to include the new role in JWT tokens

### Changing IdP

To use a different IdP (e.g., Google, Azure AD):

1. Update the `connect_url` in the configuration
2. Update the `client_id` and `client_secret`
3. Adjust the `subject_key` and `roles_key` if needed
4. Update the brand image (`files/{{ oidc.logo }}.png`)

## Support

For issues or questions regarding this OIDC setup, refer to:

- [OpenSearch Security Plugin Documentation](https://opensearch.org/docs/latest/security-plugin/configuration/openid-connect/)
- [OpenSearch Dashboards Security Documentation](https://opensearch.org/docs/latest/dashboards/security/)
