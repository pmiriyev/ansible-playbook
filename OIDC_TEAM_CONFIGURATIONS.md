# OIDC Team Configuration Guide

This guide shows how to configure OIDC for different team sizes and organizational structures.

## Configuration Options

### 1. **Small Team (2-10 people)**
### 2. **Medium Team (10-50 people)**  
### 3. **Large Enterprise (50+ people)**
### 4. **Multi-Department Organization**

---

## 🏠 **Small Team Configuration (2-10 people)**

### **Scenario**: Startup or small development team
### **Groups**: Simple role-based access

```yaml
# inventories/opensearch/group_vars/all/all.yml
oidc:
  name: "GitLab"
  logo: "gitlab"
  connect_url: https://gitlab.com/.well-known/openid-configuration
  subject_key: preferred_username
  groups_key: groups
  scopes: "openid profile email groups"
  dashboards_url: https://kibana.miriyev.ai
  client_id: "{{ lookup('bitwarden.secrets.lookup', 'your-client-id') }}"
  client_secret: "{{ lookup('bitwarden.secrets.lookup', 'your-client-secret') }}"
  enable_ssl: false
  verify_hostnames: false
  default_role: "oidc_developer"
  
  # Simple group mapping for small team
  group_mapping:
    admin: "oidc_admin"           # Team lead/CTO
    developer: "oidc_developer"   # All developers
    viewer: "oidc_viewer"         # Stakeholders, PMs
```

### **GitLab Groups Structure**:
```
Your Company
├── admin (1-2 people)
├── developer (3-8 people)  
└── viewer (1-3 people)
```

### **Roles Configuration** (`files/roles.yml`):
```yaml
# Simple roles for small team
oidc_admin:
  reserved: false
  index_permissions:
    - index_patterns:
        - "*"
      allowed_actions:
        - "*"
  tenant_permissions:
    - tenant_patterns:
        - "*"
      allowed_actions:
        - "kibana_all_write"

oidc_developer:
  reserved: false
  index_permissions:
    - index_patterns:
        - "app-*"
        - "logs-*"
        - "metrics-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "indices:data/write/index"
        - "indices:data/write/update"
        - "read"
        - "write"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "DEVELOPMENT"
      allowed_actions:
        - "kibana_all_write"

oidc_viewer:
  reserved: false
  index_permissions:
    - index_patterns:
        - "app-*"
        - "logs-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "read"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "DEVELOPMENT"
      allowed_actions:
        - "kibana_all_read"
```

### **Tenants** (`files/tenants.yml`):
```yaml
DEVELOPMENT:
  reserved: false
  description: "Main development tenant for small team"
```

---

## 🏢 **Medium Team Configuration (10-50 people)**

### **Scenario**: Growing company with multiple teams
### **Groups**: Team-based access with some specialization

```yaml
# inventories/opensearch/group_vars/all/all.yml
oidc:
  name: "GitLab"
  logo: "gitlab"
  connect_url: https://gitlab.com/.well-known/openid-configuration
  subject_key: preferred_username
  groups_key: groups
  scopes: "openid profile email groups"
  dashboards_url: https://kibana.miriyev.ai
  client_id: "{{ lookup('bitwarden.secrets.lookup', 'your-client-id') }}"
  client_secret: "{{ lookup('bitwarden.secrets.lookup', 'your-client-secret') }}"
  enable_ssl: false
  verify_hostnames: false
  default_role: "oidc_viewer"
  
  # Team-based group mapping
  group_mapping:
    # Leadership
    engineering-managers: "oidc_manager"
    product-managers: "oidc_pm"
    
    # Development teams
    backend-team: "oidc_backend_developer"
    frontend-team: "oidc_frontend_developer"
    mobile-team: "oidc_mobile_developer"
    
    # Specialized teams
    devops-team: "oidc_devops"
    qa-team: "oidc_qa_analyst"
    data-team: "oidc_data_analyst"
    
    # Support roles
    support-team: "oidc_support"
    stakeholders: "oidc_viewer"
```

### **GitLab Groups Structure**:
```
Your Company
├── Leadership
│   ├── engineering-managers
│   └── product-managers
├── Development Teams
│   ├── backend-team
│   ├── frontend-team
│   └── mobile-team
├── Specialized Teams
│   ├── devops-team
│   ├── qa-team
│   └── data-team
└── Support
    ├── support-team
    └── stakeholders
```

### **Roles Configuration**:
```yaml
# Manager role
oidc_manager:
  reserved: false
  index_permissions:
    - index_patterns:
        - "*"
      allowed_actions:
        - "indices:data/read/search*"
        - "read"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "*"
      allowed_actions:
        - "kibana_all_read"

# Product Manager role
oidc_pm:
  reserved: false
  index_permissions:
    - index_patterns:
        - "analytics-*"
        - "user-*"
        - "business-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "read"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "ANALYTICS"
        - "BUSINESS"
      allowed_actions:
        - "kibana_all_read"

# Mobile Developer role
oidc_mobile_developer:
  reserved: false
  index_permissions:
    - index_patterns:
        - "mobile-*"
        - "app-*"
        - "ios-*"
        - "android-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "indices:data/write/index"
        - "read"
        - "write"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "MOBILE"
      allowed_actions:
        - "kibana_all_write"

# Support role
oidc_support:
  reserved: false
  index_permissions:
    - index_patterns:
        - "support-*"
        - "tickets-*"
        - "user-*"
      allowed_actions:
        - "indices:data/read/search*"
        - "read"
        - "view_index_metadata"
  tenant_permissions:
    - tenant_patterns:
        - "SUPPORT"
      allowed_actions:
        - "kibana_all_read"
```

---

## 🏭 **Large Enterprise Configuration (50+ people)**

### **Scenario**: Large company with multiple departments and complex hierarchy
### **Groups**: Department-based with sub-teams and roles

```yaml
# inventories/opensearch/group_vars/all/all.yml
oidc:
  name: "GitLab"
  logo: "gitlab"
  connect_url: https://gitlab.com/.well-known/openid-configuration
  subject_key: preferred_username
  groups_key: groups
  scopes: "openid profile email groups"
  dashboards_url: https://kibana.miriyev.ai
  client_id: "{{ lookup('bitwarden.secrets.lookup', 'your-client-id') }}"
  client_secret: "{{ lookup('bitwarden.secrets.lookup', 'your-client-secret') }}"
  enable_ssl: true
  verify_hostnames: true
  default_role: "oidc_viewer"
  
  # Enterprise group mapping
  group_mapping:
    # Executive level
    c-suite: "oidc_executive"
    vp-engineering: "oidc_vp_engineering"
    vp-product: "oidc_vp_product"
    
    # Engineering departments
    platform-engineering: "oidc_platform_engineer"
    backend-engineering: "oidc_backend_engineer"
    frontend-engineering: "oidc_frontend_engineer"
    mobile-engineering: "oidc_mobile_engineer"
    data-engineering: "oidc_data_engineer"
    ml-engineering: "oidc_ml_engineer"
    
    # Operations teams
    devops-team: "oidc_devops"
    sre-team: "oidc_sre"
    security-team: "oidc_security_analyst"
    
    # Quality & Testing
    qa-team: "oidc_qa_analyst"
    test-automation: "oidc_test_automation"
    performance-qa: "oidc_performance_qa"
    
    # Product & Design
    product-team: "oidc_product_analyst"
    ux-team: "oidc_ux_analyst"
    design-team: "oidc_design_analyst"
    
    # Business & Analytics
    business-intelligence: "oidc_bi_analyst"
    data-science: "oidc_data_scientist"
    marketing-analytics: "oidc_marketing_analyst"
    
    # Support & Operations
    customer-support: "oidc_support"
    technical-support: "oidc_technical_support"
    compliance-team: "oidc_compliance"
    
    # External stakeholders
    contractors: "oidc_contractor"
    partners: "oidc_partner"
    investors: "oidc_investor"
```

### **GitLab Groups Structure**:
```
Enterprise Company
├── Executive
│   ├── c-suite
│   ├── vp-engineering
│   └── vp-product
├── Engineering
│   ├── platform-engineering
│   ├── backend-engineering
│   ├── frontend-engineering
│   ├── mobile-engineering
│   ├── data-engineering
│   └── ml-engineering
├── Operations
│   ├── devops-team
│   ├── sre-team
│   └── security-team
├── Quality
│   ├── qa-team
│   ├── test-automation
│   └── performance-qa
├── Product & Design
│   ├── product-team
│   ├── ux-team
│   └── design-team
├── Business
│   ├── business-intelligence
│   ├── data-science
│   └── marketing-analytics
├── Support
│   ├── customer-support
│   ├── technical-support
│   └── compliance-team
└── External
    ├── contractors
    ├── partners
    └── investors
```

---

## 🏢 **Multi-Department Organization**

### **Scenario**: Company with multiple business units or departments
### **Groups**: Department-based with cross-functional access

```yaml
# inventories/opensearch/group_vars/all/all.yml
oidc:
  name: "GitLab"
  logo: "gitlab"
  connect_url: https://gitlab.com/.well-known/openid-configuration
  subject_key: preferred_username
  groups_key: groups
  scopes: "openid profile email groups"
  dashboards_url: https://kibana.miriyev.ai
  client_id: "{{ lookup('bitwarden.secrets.lookup', 'your-client-id') }}"
  client_secret: "{{ lookup('bitwarden.secrets.lookup', 'your-client-secret') }}"
  enable_ssl: true
  verify_hostnames: true
  default_role: "oidc_viewer"
  
  # Multi-department group mapping
  group_mapping:
    # Department A (e.g., E-commerce)
    dept-a-admin: "oidc_dept_a_admin"
    dept-a-backend: "oidc_dept_a_backend"
    dept-a-frontend: "oidc_dept_a_frontend"
    dept-a-qa: "oidc_dept_a_qa"
    
    # Department B (e.g., Mobile Apps)
    dept-b-admin: "oidc_dept_b_admin"
    dept-b-mobile: "oidc_dept_b_mobile"
    dept-b-backend: "oidc_dept_b_backend"
    dept-b-qa: "oidc_dept_b_qa"
    
    # Department C (e.g., Analytics Platform)
    dept-c-admin: "oidc_dept_c_admin"
    dept-c-data: "oidc_dept_c_data"
    dept-c-ml: "oidc_dept_c_ml"
    dept-c-qa: "oidc_dept_c_qa"
    
    # Shared services
    shared-devops: "oidc_shared_devops"
    shared-security: "oidc_shared_security"
    shared-compliance: "oidc_shared_compliance"
    
    # Cross-department roles
    cross-dept-manager: "oidc_cross_dept_manager"
    cross-dept-analyst: "oidc_cross_dept_analyst"
```

---

## 🔧 **Configuration Templates**

### **Template 1: Minimal Setup (Small Team)**
```yaml
# Minimal configuration for 2-10 people
oidc:
  group_mapping:
    admin: "oidc_admin"
    developer: "oidc_developer"
    viewer: "oidc_viewer"
```

### **Template 2: Standard Setup (Medium Team)**
```yaml
# Standard configuration for 10-50 people
oidc:
  group_mapping:
    managers: "oidc_manager"
    backend-team: "oidc_backend_developer"
    frontend-team: "oidc_frontend_developer"
    qa-team: "oidc_qa_analyst"
    devops-team: "oidc_devops"
    support-team: "oidc_support"
    stakeholders: "oidc_viewer"
```

### **Template 3: Enterprise Setup (Large Team)**
```yaml
# Enterprise configuration for 50+ people
oidc:
  group_mapping:
    # Executive
    c-suite: "oidc_executive"
    vp-engineering: "oidc_vp_engineering"
    
    # Engineering
    platform-engineering: "oidc_platform_engineer"
    backend-engineering: "oidc_backend_engineer"
    frontend-engineering: "oidc_frontend_engineer"
    data-engineering: "oidc_data_engineer"
    
    # Operations
    devops-team: "oidc_devops"
    sre-team: "oidc_sre"
    security-team: "oidc_security_analyst"
    
    # Quality
    qa-team: "oidc_qa_analyst"
    test-automation: "oidc_test_automation"
    
    # Business
    product-team: "oidc_product_analyst"
    business-intelligence: "oidc_bi_analyst"
    data-science: "oidc_data_scientist"
    
    # Support
    customer-support: "oidc_support"
    technical-support: "oidc_technical_support"
    
    # External
    contractors: "oidc_contractor"
    partners: "oidc_partner"
```

---

## 🚀 **Quick Start Guide**

### **Step 1: Choose Your Template**
Based on your team size, select the appropriate template above.

### **Step 2: Configure Your IdP**
1. **GitLab**: Create groups matching your chosen template
2. **AWS Cognito**: Create user groups with same names
3. **Other IdPs**: Configure groups as needed

### **Step 3: Update Configuration**
1. Copy the appropriate `group_mapping` to your `all.yml`
2. Update role definitions in `files/roles.yml`
3. Update role mappings in `files/roles_mapping.yml`
4. Update tenants in `files/tenants.yml`

### **Step 4: Deploy**
```bash
ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml
```

### **Step 5: Test**
1. Assign users to groups in your IdP
2. Test authentication and role assignment
3. Verify permissions are working correctly

---

## 📊 **Scaling Recommendations**

### **Small Team (2-10 people)**
- ✅ Use simple 3-role structure (admin, developer, viewer)
- ✅ Single tenant for all data
- ✅ Broad index patterns for developers
- ✅ Minimal group hierarchy

### **Medium Team (10-50 people)**
- ✅ Team-based groups (backend-team, frontend-team, etc.)
- ✅ Multiple tenants for different data types
- ✅ Specialized roles for different functions
- ✅ Manager roles for oversight

### **Large Enterprise (50+ people)**
- ✅ Department-based groups
- ✅ Multiple tenants per department
- ✅ Granular permissions
- ✅ Executive and management roles
- ✅ External stakeholder roles
- ✅ Compliance and audit roles

### **Multi-Department Organization**
- ✅ Department-prefixed groups
- ✅ Shared service groups
- ✅ Cross-department roles
- ✅ Department-specific tenants
- ✅ Shared infrastructure access

---

## 🔄 **Migration Path**

### **Growing from Small to Medium**
1. Add team-based groups to existing structure
2. Create new roles for specialized teams
3. Add new tenants for different data types
4. Migrate users to appropriate groups

### **Growing from Medium to Large**
1. Add department-level groups
2. Create executive and management roles
3. Add compliance and audit roles
4. Implement cross-department access controls

### **Adding New Departments**
1. Create department-specific groups
2. Add department-specific roles and tenants
3. Configure cross-department access as needed
4. Update shared service access

This configuration system is designed to grow with your organization while maintaining security and ease of management.
