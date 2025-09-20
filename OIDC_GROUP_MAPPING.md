# OIDC Group-Based Role Mapping

This document explains how to configure OpenSearch to map OIDC groups (from GitLab, AWS Cognito, etc.) to OpenSearch roles.

## How Group-Based Role Mapping Works

### 1. **JWT Token Structure**
When a user authenticates via OIDC, the JWT token contains group information:

```json
{
  "sub": "user123",
  "preferred_username": "john.doe",
  "groups": ["devops", "backend", "qa"],
  "roles": ["opensearch_admin", "opensearch_readonly"]
}
```

### 2. **Group to Role Mapping Process**
1. User authenticates via OIDC (GitLab/AWS)
2. JWT token contains `groups` claim with group names
3. OpenSearch maps groups to backend roles
4. Backend roles are mapped to OpenSearch roles
5. User gets appropriate permissions

## Configuration

### GitLab Groups Example

**GitLab Group Structure:**
```
Company
├── DevOps Team (devops)
├── Backend Team (backend)
├── Frontend Team (frontend)
├── QA Team (qa)
├── Security Team (security)
└── Data Team (data)
```

**JWT Token Groups Claim:**
```json
{
  "groups": ["devops", "backend"]
}
```

### AWS Cognito Groups Example

**AWS Cognito Group Structure:**
```
User Pool
├── DevOpsGroup
├── BackendGroup
├── FrontendGroup
├── QAGroup
├── SecurityGroup
└── DataGroup
```

**JWT Token Groups Claim:**
```json
{
  "cognito:groups": ["DevOpsGroup", "BackendGroup"]
}
```

## Role Mapping Configuration

### 1. **Backend Role Mapping** (`files/roles_mapping.yml`)

```yaml
# Group-based OIDC role mappings
oidc_backend_developer:
  reserved: false
  backend_roles:
    - "backend"           # GitLab group
    - "BackendGroup"      # AWS Cognito group
  description: "Maps OIDC backend developers to backend indexes"

oidc_frontend_developer:
  reserved: false
  backend_roles:
    - "frontend"          # GitLab group
    - "FrontendGroup"     # AWS Cognito group
  description: "Maps OIDC frontend developers to frontend indexes"

oidc_qa_analyst:
  reserved: false
  backend_roles:
    - "qa"                # GitLab group
    - "QAGroup"           # AWS Cognito group
  description: "Maps OIDC QA analysts to testing indexes"
```

### 2. **Role Definitions** (`files/roles.yml`)

```yaml
oidc_backend_developer:
  reserved: false
  index_permissions:
    - index_patterns:
        - "backend-*"
        - "api-*"
        - "service-*"
        - "application-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "indices:data/write/index"
        - "indices:data/write/update"
        - "indices:data/write/delete"
        - "read"
        - "write"
        - "view_index_metadata"
        - "create_index"
        - "delete_index"
  tenant_permissions:
    - tenant_patterns:
        - "BACKEND"
        - "API"
      allowed_actions:
        - "kibana_all_write"
```

## Available Roles and Permissions

### **DevOps Role** (`oidc_admin`)
- **Groups**: `devops`, `DevOpsGroup`
- **Permissions**: Full access to all indices and tenants
- **Use Case**: Infrastructure monitoring, cluster management

### **Backend Developer Role** (`oidc_backend_developer`)
- **Groups**: `backend`, `BackendGroup`
- **Permissions**: 
  - Read/Write access to: `backend-*`, `api-*`, `service-*`, `application-*`
  - Can create/delete indices
  - Access to BACKEND and API tenants
- **Use Case**: Application logs, API monitoring, service metrics

### **Frontend Developer Role** (`oidc_frontend_developer`)
- **Groups**: `frontend`, `FrontendGroup`
- **Permissions**:
  - Read/Write access to: `frontend-*`, `ui-*`, `web-*`, `client-*`
  - Access to FRONTEND and WEB tenants
- **Use Case**: UI logs, client-side monitoring, web analytics

### **QA Analyst Role** (`oidc_qa_analyst`)
- **Groups**: `qa`, `QAGroup`
- **Permissions**:
  - Read/Write access to: `test-*`, `qa-*`, `automation-*`, `performance-*`
  - Access to QA and TESTING tenants
- **Use Case**: Test results, automation logs, performance metrics

### **Security Analyst Role** (`oidc_security_analyst`)
- **Groups**: `security`, `SecurityGroup`
- **Permissions**:
  - Read access to: `kube-apiserver-audit-*`, `syslog-*`, `security-*`
  - Access to SECURITY tenant
- **Use Case**: Security logs, audit trails, threat analysis

### **Data Analyst Role** (`oidc_data_analyst`)
- **Groups**: `data`, `DataGroup`
- **Permissions**:
  - Read/Write access to: `data-*`, `analytics-*`, `metrics-*`, `logs-*`
  - Access to DATA and ANALYTICS tenants
- **Use Case**: Data analysis, metrics dashboards, business intelligence

## Setup Instructions

### 1. **Configure Your IdP**

#### GitLab Configuration:
1. Go to your GitLab project/group settings
2. Navigate to "Access Tokens" or "Applications"
3. Create an OAuth application with these scopes:
   - `openid`
   - `profile`
   - `email`
   - `groups` (important for group information)
4. Set redirect URI to: `https://kibana.miriyev.ai`

#### AWS Cognito Configuration:
1. Create a User Pool in AWS Cognito
2. Create groups: `DevOpsGroup`, `BackendGroup`, `FrontendGroup`, etc.
3. Assign users to appropriate groups
4. Configure OAuth flows with these scopes:
   - `openid`
   - `profile`
   - `email`
   - `aws.cognito.signin.user.admin` (for group information)

### 2. **Update Configuration**

Update `inventories/opensearch/group_vars/all/all.yml`:

```yaml
oidc:
  # For GitLab
  groups_key: groups
  # For AWS Cognito
  # groups_key: cognito:groups
  
  group_mapping:
    # GitLab groups
    devops: "oidc_admin"
    backend: "oidc_backend_developer"
    frontend: "oidc_frontend_developer"
    qa: "oidc_qa_analyst"
    security: "oidc_security_analyst"
    data: "oidc_data_analyst"
    
    # AWS Cognito groups (uncomment if using AWS)
    # DevOpsGroup: "oidc_admin"
    # BackendGroup: "oidc_backend_developer"
    # FrontendGroup: "oidc_frontend_developer"
    # QAGroup: "oidc_qa_analyst"
    # SecurityGroup: "oidc_security_analyst"
    # DataGroup: "oidc_data_analyst"
```

### 3. **Deploy Configuration**

```bash
ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml
```

## Testing Group Mapping

### 1. **Check JWT Token**
Use a JWT decoder to verify your token contains group information:

```bash
# Example JWT payload
{
  "sub": "user123",
  "preferred_username": "john.doe",
  "groups": ["backend", "qa"],
  "iat": 1640995200,
  "exp": 1640998800
}
```

### 2. **Test Authentication**
1. Navigate to `https://kibana.miriyev.ai`
2. Click "Log in with GitLab" (or your IdP)
3. After authentication, check your assigned roles in OpenSearch Dashboards

### 3. **Verify Permissions**
- Try accessing different indices based on your group membership
- Check tenant access in OpenSearch Dashboards
- Verify you can only see data relevant to your groups

## Troubleshooting

### Common Issues:

1. **Groups Not Appearing in JWT**
   - Ensure `groups` scope is requested in OAuth application
   - Check IdP configuration for group claims
   - Verify user is assigned to groups in IdP

2. **Role Mapping Not Working**
   - Check `groups_key` configuration matches JWT claim name
   - Verify group names in role mappings match JWT groups exactly
   - Check OpenSearch security logs for mapping errors

3. **Permission Denied**
   - Verify user is assigned to correct groups in IdP
   - Check role definitions have appropriate permissions
   - Ensure index patterns match your actual indices

### Debug Commands:

```bash
# Check OpenSearch security configuration
curl -X GET "https://localhost:9200/_plugins/_security/api/rolesmapping" \
  -u admin:password -k

# Check user roles
curl -X GET "https://localhost:9200/_plugins/_security/api/internalusers" \
  -u admin:password -k

# Check security logs
tail -f /var/log/opensearch/opensearch.log | grep -i security
```

## Best Practices

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Regular Audits**: Review group memberships and role assignments
3. **Index Naming**: Use consistent naming patterns for easy role mapping
4. **Tenant Organization**: Organize dashboards by teams/tenants
5. **Monitoring**: Monitor authentication and authorization logs

## Example Scenarios

### Scenario 1: Backend Developer
- **Groups**: `["backend"]`
- **Access**: `backend-*`, `api-*`, `service-*` indices
- **Tenants**: BACKEND, API
- **Permissions**: Read/Write, can create indices

### Scenario 2: QA Analyst
- **Groups**: `["qa"]`
- **Access**: `test-*`, `qa-*`, `automation-*` indices
- **Tenants**: QA, TESTING
- **Permissions**: Read/Write, cannot delete indices

### Scenario 3: Multi-Group User
- **Groups**: `["backend", "qa"]`
- **Access**: Both backend and QA indices
- **Tenants**: BACKEND, API, QA, TESTING
- **Permissions**: Combined permissions from both roles

This setup provides flexible, group-based access control that scales with your organization's structure.
