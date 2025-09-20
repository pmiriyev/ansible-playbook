#!/bin/bash

# OIDC Configuration Setup Script
# This script helps you choose the right OIDC configuration for your team size

echo "🚀 OpenSearch OIDC Configuration Setup"
echo "======================================"
echo ""

# Function to display team size options
show_team_options() {
    echo "Please select your team size:"
    echo ""
    echo "1) Small Team (2-10 people)"
    echo "   - Simple 3-role structure (admin, developer, viewer)"
    echo "   - Single tenant for all data"
    echo "   - Perfect for startups and small development teams"
    echo ""
    echo "2) Medium Team (10-50 people)"
    echo "   - Team-based groups (backend-team, frontend-team, etc.)"
    echo "   - Multiple tenants for different data types"
    echo "   - Specialized roles for different functions"
    echo ""
    echo "3) Large Enterprise (50+ people)"
    echo "   - Department-based groups"
    echo "   - Multiple tenants per department"
    echo "   - Granular permissions and compliance roles"
    echo ""
    echo "4) Multi-Department Organization"
    echo "   - Department-prefixed groups"
    echo "   - Shared service groups"
    echo "   - Cross-department access controls"
    echo ""
}

# Function to setup small team configuration
setup_small_team() {
    echo "🏠 Setting up Small Team Configuration..."
    echo ""
    
    # Copy configuration files
    cp examples/small-team-config.yml inventories/opensearch/group_vars/all/all.yml
    cp examples/small-team-roles.yml files/roles.yml
    cp examples/small-team-role-mappings.yml files/roles_mapping.yml
    cp examples/small-team-tenants.yml files/tenants.yml
    
    echo "✅ Small team configuration files copied!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update your GitLab OAuth application with these scopes:"
    echo "   - openid"
    echo "   - profile"
    echo "   - email"
    echo "   - groups"
    echo ""
    echo "2. Create these groups in GitLab:"
    echo "   - admin (for team leads/CTOs)"
    echo "   - developer (for all developers)"
    echo "   - viewer (for stakeholders, PMs)"
    echo ""
    echo "3. Update client_id and client_secret in all.yml"
    echo ""
    echo "4. Deploy with: ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml"
    echo ""
}

# Function to setup medium team configuration
setup_medium_team() {
    echo "🏢 Setting up Medium Team Configuration..."
    echo ""
    
    # Copy configuration files
    cp examples/medium-team-config.yml inventories/opensearch/group_vars/all/all.yml
    # Note: For medium team, we use the existing comprehensive roles from the main setup
    
    echo "✅ Medium team configuration files copied!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update your GitLab OAuth application with these scopes:"
    echo "   - openid"
    echo "   - profile"
    echo "   - email"
    echo "   - groups"
    echo ""
    echo "2. Create these groups in GitLab:"
    echo "   - engineering-managers"
    echo "   - product-managers"
    echo "   - backend-team"
    echo "   - frontend-team"
    echo "   - mobile-team"
    echo "   - devops-team"
    echo "   - qa-team"
    echo "   - data-team"
    echo "   - support-team"
    echo "   - stakeholders"
    echo ""
    echo "3. Update client_id and client_secret in all.yml"
    echo ""
    echo "4. Deploy with: ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml"
    echo ""
}

# Function to setup enterprise configuration
setup_enterprise() {
    echo "🏭 Setting up Enterprise Configuration..."
    echo ""
    
    # Copy configuration files
    cp examples/enterprise-config.yml inventories/opensearch/group_vars/all/all.yml
    # Note: For enterprise, we use the existing comprehensive roles from the main setup
    
    echo "✅ Enterprise configuration files copied!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update your GitLab OAuth application with these scopes:"
    echo "   - openid"
    echo "   - profile"
    echo "   - email"
    echo "   - groups"
    echo ""
    echo "2. Create these groups in GitLab:"
    echo "   - c-suite"
    echo "   - vp-engineering"
    echo "   - vp-product"
    echo "   - platform-engineering"
    echo "   - backend-engineering"
    echo "   - frontend-engineering"
    echo "   - mobile-engineering"
    echo "   - data-engineering"
    echo "   - ml-engineering"
    echo "   - devops-team"
    echo "   - sre-team"
    echo "   - security-team"
    echo "   - qa-team"
    echo "   - test-automation"
    echo "   - performance-qa"
    echo "   - product-team"
    echo "   - ux-team"
    echo "   - design-team"
    echo "   - business-intelligence"
    echo "   - data-science"
    echo "   - marketing-analytics"
    echo "   - customer-support"
    echo "   - technical-support"
    echo "   - compliance-team"
    echo "   - contractors"
    echo "   - partners"
    echo "   - investors"
    echo ""
    echo "3. Update client_id and client_secret in all.yml"
    echo ""
    echo "4. Deploy with: ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml"
    echo ""
}

# Function to setup multi-department configuration
setup_multi_department() {
    echo "🏢 Setting up Multi-Department Configuration..."
    echo ""
    
    echo "For multi-department setup, you'll need to customize the configuration."
    echo "Please refer to OIDC_TEAM_CONFIGURATIONS.md for detailed instructions."
    echo ""
    echo "📋 Key considerations:"
    echo "1. Create department-prefixed groups (e.g., dept-a-admin, dept-b-backend)"
    echo "2. Configure shared service groups (shared-devops, shared-security)"
    echo "3. Set up cross-department access controls"
    echo "4. Create department-specific tenants"
    echo ""
}

# Main script logic
show_team_options

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_small_team
        ;;
    2)
        setup_medium_team
        ;;
    3)
        setup_enterprise
        ;;
    4)
        setup_multi_department
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again and select 1-4."
        exit 1
        ;;
esac

echo "🎉 Configuration setup complete!"
echo ""
echo "📚 For more information, see:"
echo "   - OIDC_TEAM_CONFIGURATIONS.md (detailed configuration guide)"
echo "   - OIDC_GROUP_MAPPING.md (group mapping documentation)"
echo "   - OIDC_SETUP.md (general OIDC setup guide)"
echo ""
echo "🔧 For troubleshooting, check the documentation or run:"
echo "   ansible-playbook -i inventories/opensearch/hosts.ini opensearch.yml --check"
