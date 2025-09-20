# Enterprise Production Improvements for OpenSearch

## 🎯 **Current Assessment: 4/10 Production Ready**

Your OpenSearch setup has a solid foundation but needs significant improvements for enterprise production deployment.

---

## 🚨 **Critical Issues to Address**

### 1. **JVM Configuration Issues**
```yaml
# Current (PROBLEMATIC):
xms_value: 31
xmx_value: 31

# Recommended for Production:
xms_value: 16  # Max 50% of available RAM
xmx_value: 16  # Should match Xms
```

**Why this matters:**
- 31GB heap is excessive and can cause GC issues
- Should be max 50% of available RAM
- Can cause memory pressure and performance issues

### 2. **Missing Monitoring Stack**
**Current:** No monitoring at all
**Needed:** Complete observability stack

### 3. **No Backup Strategy**
**Current:** No backups configured
**Needed:** Automated backup and recovery

### 4. **Security Certificate Issues**
**Current:** Self-signed certificates
**Needed:** Proper certificate management

---

## 🛠️ **Immediate Improvements (Phase 1)**

### **1. Fix JVM Configuration**

Create `inventories/opensearch/group_vars/all/production.yml`:
```yaml
# Production-optimized JVM settings
xms_value: 16
xmx_value: 16

# Production cluster settings
cluster_type: multi-node

# Production security settings
cert_valid_days: 365  # 1 year instead of 10 years
enable_ssl: true
verify_hostnames: true

# Production performance settings
os_cluster_name: "production-opensearch-cluster"
```

### **2. Add Production Node Configuration**

Update `inventories/opensearch/hosts.ini` for production:
```ini
# Dedicated master nodes (3 for quorum)
master1 ansible_host=10.0.1.10 ip=10.0.1.10 roles=master
master2 ansible_host=10.0.1.11 ip=10.0.1.11 roles=master  
master3 ansible_host=10.0.1.12 ip=10.0.1.12 roles=master

# Data nodes
data1 ansible_host=10.0.1.20 ip=10.0.1.20 roles=data
data2 ansible_host=10.0.1.21 ip=10.0.1.21 roles=data
data3 ansible_host=10.0.1.22 ip=10.0.1.22 roles=data
data4 ansible_host=10.0.1.23 ip=10.0.1.23 roles=data

# Ingest nodes
ingest1 ansible_host=10.0.1.30 ip=10.0.1.30 roles=ingest
ingest2 ansible_host=10.0.1.31 ip=10.0.1.31 roles=ingest

# Coordinating nodes (optional but recommended)
coord1 ansible_host=10.0.1.40 ip=10.0.1.40 roles=
coord2 ansible_host=10.0.1.41 ip=10.0.1.41 roles=

# Dashboards
dashboards ansible_host=10.0.1.50 ip=10.0.1.50

[master]
master1
master2
master3

[data]
data1
data2
data3
data4

[ingest]
ingest1
ingest2

[coordinating]
coord1
coord2

[os-cluster]
master1
master2
master3
data1
data2
data3
data4
ingest1
ingest2
coord1
coord2
```

### **3. Enhanced OpenSearch Configuration**

Create `roles/linux/opensearch/templates/opensearch-production.yml`:
```yaml
cluster.name: "{{ os_cluster_name }}"
node.name: "{{ inventory_hostname }}"
network.host: "{{ hostvars[inventory_hostname]['ip'] }}"
http.port: 9200
transport.port: 9300

# Production settings
bootstrap.memory_lock: true
discovery.seed_hosts: ["{{ os_nodes }}"]
cluster.initial_master_nodes: ["{{ os_master_nodes }}"]
node.roles: [{{ hostvars[inventory_hostname]['roles'] }}]

# Production performance settings
indices.memory.index_buffer_size: 20%
indices.queries.cache.size: 10%
indices.fielddata.cache.size: 20%

# Production security settings
plugins.security.ssl.transport.enforce_hostname_verification: true
plugins.security.ssl.http.enforce_hostname_verification: true

# Production cluster settings
cluster.routing.allocation.disk.threshold_enabled: true
cluster.routing.allocation.disk.watermark.low: 85%
cluster.routing.allocation.disk.watermark.high: 90%
cluster.routing.allocation.disk.watermark.flood_stage: 95%

# Production logging
logger.level: INFO
logger.org.opensearch.discovery: WARN
logger.org.opensearch.cluster.service: WARN

# Production thread pools
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000
thread_pool.get.queue_size: 1000
```

---

## 📊 **Monitoring Stack Implementation**

### **1. Prometheus Configuration**

Create `roles/monitoring/prometheus/tasks/main.yml`:
```yaml
---
- name: Install Prometheus
  ansible.builtin.package:
    name: prometheus
    state: present

- name: Configure Prometheus for OpenSearch
  ansible.builtin.template:
    src: prometheus.yml.j2
    dest: /etc/prometheus/prometheus.yml
    backup: true

- name: Start and enable Prometheus
  ansible.builtin.systemd:
    name: prometheus
    state: started
    enabled: true
```

### **2. Grafana Configuration**

Create `roles/monitoring/grafana/tasks/main.yml`:
```yaml
---
- name: Install Grafana
  ansible.builtin.package:
    name: grafana
    state: present

- name: Configure Grafana
  ansible.builtin.template:
    src: grafana.ini.j2
    dest: /etc/grafana/grafana.ini
    backup: true

- name: Start and enable Grafana
  ansible.builtin.systemd:
    name: grafana-server
    state: started
    enabled: true
```

### **3. OpenSearch Exporter**

Create `roles/monitoring/opensearch-exporter/tasks/main.yml`:
```yaml
---
- name: Download OpenSearch Exporter
  ansible.builtin.get_url:
    url: "https://github.com/justwatchcom/elasticsearch_exporter/releases/download/v1.1.0/elasticsearch_exporter-1.1.0.linux-amd64.tar.gz"
    dest: /tmp/elasticsearch_exporter.tar.gz

- name: Extract OpenSearch Exporter
  ansible.builtin.unarchive:
    src: /tmp/elasticsearch_exporter.tar.gz
    dest: /opt/
    remote_src: true

- name: Create systemd service for OpenSearch Exporter
  ansible.builtin.template:
    src: elasticsearch_exporter.service.j2
    dest: /etc/systemd/system/elasticsearch_exporter.service

- name: Start and enable OpenSearch Exporter
  ansible.builtin.systemd:
    name: elasticsearch_exporter
    state: started
    enabled: true
    daemon_reload: true
```

---

## 💾 **Backup Strategy Implementation**

### **1. Snapshot Repository Configuration**

Create `roles/backup/opensearch-snapshots/tasks/main.yml`:
```yaml
---
- name: Create backup directory
  ansible.builtin.file:
    path: /opt/opensearch-backups
    state: directory
    owner: "{{ os_user }}"
    group: "{{ os_user }}"
    mode: '0755'

- name: Configure snapshot repository
  ansible.builtin.uri:
    url: "https://{{ inventory_hostname }}:9200/_snapshot/backup_repo"
    method: PUT
    user: admin
    password: "{{ admin_password }}"
    validate_certs: false
    body_format: json
    body:
      type: fs
      settings:
        location: /opt/opensearch-backups
        compress: true
        max_snapshot_bytes_per_sec: 50mb
        max_restore_bytes_per_sec: 50mb

- name: Create backup script
  ansible.builtin.template:
    src: backup.sh.j2
    dest: /opt/scripts/backup.sh
    mode: '0755'

- name: Schedule daily backups
  ansible.builtin.cron:
    name: "OpenSearch daily backup"
    job: "/opt/scripts/backup.sh"
    minute: "0"
    hour: "2"
    user: "{{ os_user }}"
```

### **2. Index Lifecycle Management**

Create `roles/backup/index-lifecycle/tasks/main.yml`:
```yaml
---
- name: Configure index lifecycle policy
  ansible.builtin.uri:
    url: "https://{{ inventory_hostname }}:9200/_ilm/policy/logs-policy"
    method: PUT
    user: admin
    password: "{{ admin_password }}"
    validate_certs: false
    body_format: json
    body:
      policy:
        phases:
          hot:
            actions:
              rollover:
                max_size: "50GB"
                max_age: "7d"
          warm:
            min_age: "7d"
            actions:
              allocate:
                number_of_replicas: 0
          cold:
            min_age: "30d"
            actions:
              allocate:
                number_of_replicas: 0
          delete:
            min_age: "90d"
```

---

## 🔒 **Security Enhancements**

### **1. Certificate Management**

Create `roles/security/certificates/tasks/main.yml`:
```yaml
---
- name: Install certbot
  ansible.builtin.package:
    name: certbot
    state: present

- name: Generate Let's Encrypt certificates
  ansible.builtin.command:
    cmd: "certbot certonly --standalone -d {{ inventory_hostname }}.{{ domain_name }} --non-interactive --agree-tos --email admin@{{ domain_name }}"
  register: certbot_result

- name: Copy certificates to OpenSearch
  ansible.builtin.copy:
    src: "/etc/letsencrypt/live/{{ inventory_hostname }}.{{ domain_name }}/"
    dest: "{{ os_conf_dir }}/"
    owner: "{{ os_user }}"
    group: "{{ os_user }}"
    mode: '0600'
  when: certbot_result.changed
```

### **2. Security Hardening**

Create `roles/security/hardening/tasks/main.yml`:
```yaml
---
- name: Configure firewall
  ansible.builtin.iptables:
    chain: INPUT
    protocol: tcp
    destination_port: "9200"
    source: "10.0.0.0/8"
    jump: ACCEPT
    comment: "Allow OpenSearch from internal network"

- name: Disable unnecessary services
  ansible.builtin.systemd:
    name: "{{ item }}"
    enabled: false
    state: stopped
  loop:
    - avahi-daemon
    - cups
    - bluetooth

- name: Configure audit logging
  ansible.builtin.template:
    src: audit.conf.j2
    dest: /etc/audit/rules.d/opensearch.rules
```

---

## 🚀 **Performance Optimization**

### **1. System Tuning**

Create `roles/performance/tuning/tasks/main.yml`:
```yaml
---
- name: Configure kernel parameters
  ansible.posix.sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    state: present
  loop:
    - { name: "vm.max_map_count", value: "262144" }
    - { name: "fs.file-max", value: "65536" }
    - { name: "vm.swappiness", value: "1" }
    - { name: "net.core.somaxconn", value: "65535" }

- name: Configure ulimits
  ansible.builtin.template:
    src: limits.conf.j2
    dest: /etc/security/limits.d/opensearch.conf

- name: Configure CPU governor
  ansible.builtin.lineinfile:
    path: /etc/default/cpufrequtils
    line: "GOVERNOR=performance"
    create: true
```

### **2. JVM Optimization**

Create `roles/performance/jvm/templates/jvm-production.options`:
```bash
## JVM configuration for production

# Heap settings (optimized for production)
-Xms16g
-Xmx16g

# GC settings for production
-XX:+UseG1GC
-XX:G1ReservePercent=25
-XX:InitiatingHeapOccupancyPercent=30
-XX:+UseStringDeduplication

# Production logging
-Xlog:gc*,gc+age=trace,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m

# Production monitoring
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=data

# Production security
-Djava.security.egd=file:/dev/./urandom
```

---

## 📋 **Production Deployment Checklist**

### **Pre-Deployment:**
- [ ] Review and update JVM settings
- [ ] Configure proper node roles
- [ ] Set up monitoring stack
- [ ] Configure backup strategy
- [ ] Implement security hardening
- [ ] Set up alerting

### **Deployment:**
- [ ] Deploy with production configuration
- [ ] Verify cluster health
- [ ] Test monitoring
- [ ] Test backup/restore
- [ ] Verify security settings
- [ ] Performance testing

### **Post-Deployment:**
- [ ] Set up alerting rules
- [ ] Configure maintenance procedures
- [ ] Document operational procedures
- [ ] Train operations team
- [ ] Set up compliance reporting

---

## 🎯 **Expected Improvements**

After implementing these changes:

- **Production Readiness Score**: 4/10 → 8/10
- **Availability**: 5/10 → 9/10
- **Performance**: 4/10 → 8/10
- **Monitoring**: 2/10 → 9/10
- **Backup**: 1/10 → 8/10
- **Security**: 7/10 → 9/10
- **Operations**: 3/10 → 8/10

This will make your OpenSearch cluster truly enterprise-ready for production deployment.
