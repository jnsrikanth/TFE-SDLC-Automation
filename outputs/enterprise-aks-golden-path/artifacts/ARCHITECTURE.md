# Enterprise AKS Module - Architecture Documentation

## Overview

This document describes the architecture, design decisions, and patterns used in the Enterprise AKS Terraform module.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Resource Group                            │ │
│  │                                                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Virtual Network (Azure CNI)             │  │ │
│  │  │                                                       │  │ │
│  │  │  ┌──────────────────────────────────────────────┐   │  │ │
│  │  │  │         AKS Subnet (10.240.0.0/16)           │   │  │ │
│  │  │  │                                               │   │  │ │
│  │  │  │  ┌────────────────────────────────────────┐  │   │  │ │
│  │  │  │  │   AKS Control Plane (Managed by Azure) │  │   │  │ │
│  │  │  │  │   • API Server                          │  │   │  │ │
│  │  │  │  │   • etcd                                │  │   │  │ │
│  │  │  │  │   • Controller Manager                  │  │   │  │ │
│  │  │  │  │   • Scheduler                           │  │   │  │ │
│  │  │  │  └────────────────────────────────────────┘  │   │  │ │
│  │  │  │                                               │   │  │ │
│  │  │  │  ┌────────────────────────────────────────┐  │   │  │ │
│  │  │  │  │   System Node Pool (Zone 1,2,3)        │  │   │  │ │
│  │  │  │  │   • 3-10 nodes (auto-scaled)            │  │   │  │ │
│  │  │  │  │   • Standard_D4s_v5                     │  │   │  │ │
│  │  │  │  │   • Taint: CriticalAddonsOnly           │  │   │  │ │
│  │  │  │  └────────────────────────────────────────┘  │   │  │ │
│  │  │  │                                               │   │  │ │
│  │  │  │  ┌────────────────────────────────────────┐  │   │  │ │
│  │  │  │  │   User Node Pools (Zone 1,2,3)         │  │   │  │ │
│  │  │  │  │   • Application workloads               │  │   │  │ │
│  │  │  │  │   • Configurable size & count           │  │   │  │ │
│  │  │  │  │   • Optional GPU support                │  │   │  │ │
│  │  │  │  └────────────────────────────────────────┘  │   │  │ │
│  │  │  └──────────────────────────────────────────────┘   │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │                                                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Monitoring & Security                    │  │ │
│  │  │  • Azure Monitor (Container Insights)                 │  │ │
│  │  │  • Log Analytics Workspace                            │  │ │
│  │  │  • Microsoft Defender for Containers                  │  │ │
│  │  │  • Azure Policy Add-on                                │  │ │
│  │  │  • Key Vault Secrets Provider                         │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### Azure CNI Networking

**Design Decision**: Azure CNI (Container Networking Interface) was chosen over Kubenet for the following reasons:

1. **Direct Pod IP Addressing**: Pods get IPs directly from the VNet subnet
2. **Network Policy Support**: Native Azure Network Policies for pod-to-pod communication
3. **Integration**: Seamless integration with Azure services (ACR, Key Vault, Storage)
4. **Performance**: Lower latency as no NAT translation required
5. **Security**: Fine-grained network segmentation at pod level

### Network Segmentation

```
┌─────────────────────────────────────────────────────────────────┐
│                    VNet: 10.0.0.0/8                              │
│                                                                   │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │  AKS Subnet         │  │  Services Subnet    │               │
│  │  10.240.0.0/16      │  │  10.241.0.0/16      │               │
│  │  • Node IPs         │  │  • ACR              │               │
│  │  • Pod IPs          │  │  • Key Vault        │               │
│  └─────────────────────┘  │  • Storage          │               │
│                            └─────────────────────┘               │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │  Gateway Subnet     │  │  Bastion Subnet     │               │
│  │  10.242.0.0/27      │  │  10.242.1.0/27      │               │
│  │  • VPN Gateway      │  │  • Azure Bastion    │               │
│  └─────────────────────┘  └─────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### Service CIDR vs Pod CIDR

- **Service CIDR**: `10.0.0.0/16` (Kubernetes internal services)
- **Pod Subnetto**: Pod IPs come from VNet subnet (Azure CNI)
- **Docker Bridge**: `172.17.0.1/16` (internal Docker networking)
- **DNS Service IP**: `10.0.0.10` (CoreDNS)

## Security Architecture

### Defense in Depth

```
Layer 7: Application Security
  └─ Pod Security Policies
  └─ Network Policies
  └─ Azure Policy Enforcement

Layer 6: Data Security  
  └─ Key Vault Integration for Secrets
  └─ Disk Encryption (Azure Managed Keys)
  └─ TLS for all traffic

Layer 5: Identity & Access
  └─ Azure AD Integration
  └─ Managed Identities (No credentials)
  └─ RBAC at cluster and namespace level
  └─ Disabled local admin accounts

Layer 4: Network Security
  └─ Private Cluster (optional)
  └─ Network Policies (pod-to-pod)
  └─ NSG on subnet level
  └─ Standard Load Balancer

Layer 3: Monitoring & Detection
  └─ Container Insights Metrics
  └─ Control Plane Audit Logs
  └─ Microsoft Defender Threat Detection
  └─ Azure Sentinel integration ready

Layer 2: Infrastructure Security
  └─ Multi-AZ deployment for HA
  └─ Managed Kubernetes (patched by Azure)
  └─ Automatic security updates

Layer 1: Compliance & Governance
  └─ Azure Policy enforcement
  └─ Compliance scanning (Checkov)
  └─ Security baselines (CIS)
```

### Identity Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Azure Active Directory                   │
│                                                                │
│  ┌────────────────────┐        ┌────────────────────┐        │
│  │  Admin AAD Group   │        │  Developer Group   │        │
│  │  cluster-admin     │        │  namespace-editors │        │
│  └────────────────────┘        └────────────────────┘        │
│           │                              │                    │
└───────────┼──────────────────────────────┼────────────────────┘
            │                              │
            ▼                              ▼
┌───────────────────────────────────────────────────────────────┐
│                   AKS Cluster (AAD Integrated)                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Kubernetes RBAC (Azure RBAC)                 │ │
│  │                                                            │ │
│  │  Admin Group → ClusterRoleBinding → cluster-admin         │ │
│  │  Dev Group   → RoleBinding (ns:prod) → edit               │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Managed Identities                           │ │
│  │                                                            │ │
│  │  Control Plane → System Assigned Identity                 │ │
│  │  Kubelet       → System Assigned Identity                 │ │
│  │  OMS Agent     → Managed Identity → Log Analytics         │ │
│  │  CSI Driver    → Managed Identity → Key Vault             │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Design Rationale**:
- **No Service Principals**: Managed identities eliminate credential management
- **Azure RBAC**: Native Azure RBAC for Kubernetes (vs standalone K8s RBAC)
- **AAD Groups**: Centralized access management via AAD groups
- **Least Privilege**: Each component gets only required permissions

## High Availability Architecture

### Multi-Zone Deployment

```
┌────────────────────────────────────────────────────────────────┐
│                      Azure Region (e.g., East US)              │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │  Zone 1      │    │  Zone 2      │    │  Zone 3      │     │
│  │              │    │              │    │              │     │
│  │  ┌────────┐  │    │  ┌────────┐  │    │  ┌────────┐  │     │
│  │  │ Node 1 │  │    │  │ Node 2 │  │    │  │ Node 3 │  │     │
│  │  │ System │  │    │  │ System │  │    │  │ System │  │     │
│  │  └────────┘  │    │  └────────┘  │    │  └────────┘  │     │
│  │              │    │              │    │              │     │
│  │  ┌────────┐  │    │  ┌────────┐  │    │  ┌────────┐  │     │
│  │  │ Node 4 │  │    │  │ Node 5 │  │    │  │ Node 6 │  │     │
│  │  │  Apps  │  │    │  │  Apps  │  │    │  │  Apps  │  │     │
│  │  └────────┘  │    │  └────────┘  │    │  └────────┘  │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
└────────────────────────────────────────────────────────────────┘
```

**SLA Guarantees**:
- **Single Zone**: 99.5% uptime SLA
- **Multi-Zone (3 zones)**: 99.95% uptime SLA
- **Control Plane**: 99.95% (Azure managed, multi-zone by default)

### Auto-Scaling Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    Auto-Scaling Architecture                     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Horizontal Pod Autoscaler (HPA)                  │   │
│  │         Scales: Deployments based on CPU/Memory          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Cluster Autoscaler (CA)                          │   │
│  │         Scales: Node pool size (3-10 nodes)              │   │
│  │         Triggers:                                         │   │
│  │           • Pods pending due to insufficient resources    │   │
│  │           • Node utilization < 50% for 10 minutes         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Azure Virtual Machine Scale Sets (VMSS)          │   │
│  │         Provisions/Deprovisions: Actual VMs              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Upgrade Strategy

**Control Plane Upgrades**:
- Managed by Azure automatically (when `automatic_channel_upgrade` = "stable")
- Zero downtime (clustered etcd, multiple API servers)
- Scheduled during maintenance windows (configurable)

**Node Pool Upgrades**:
- Surge upgrade with 33% max surge
- Drains pods gracefully before terminating nodes
- Respects Pod Disruption Budgets (PDBs)

```
Initial State:    [Node1] [Node2] [Node3]

Surge +1:         [Node1] [Node2] [Node3] [Node4-new]
                                           ↑ New version

Drain Node1:      [Node1] [Node2] [Node3] [Node4]
                    ↓ Draining...

Replace:          [Node4] [Node2] [Node3] [Node5-new]
                                           ↑ New version

Final State:      [Node4] [Node5] [Node6]
                     All nodes on new version
```

## Monitoring Architecture

### Observability Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                       AKS Cluster                                │
│                                                                   │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  Container       │         │  Metrics         │              │
│  │  Logs            │────────▶│  Server          │              │
│  │  (stdout/stderr) │         │  (cAdvisor)      │              │
│  └──────────────────┘         └──────────────────┘              │
│           │                             │                        │
│           │                             │                        │
└───────────┼─────────────────────────────┼────────────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Azure Monitor (Container Insights)                 │
│                                                                   │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  Log Analytics   │         │  Metrics Store   │              │
│  │  • Container logs│         │  • CPU/Memory    │              │
│  │  • K8s events    │         │  • Network       │              │
│  │  • Audit logs    │         │  • Disk I/O      │              │
│  └──────────────────┘         └──────────────────┘              │
│           │                             │                        │
└───────────┼──────────────────────── ────┼────────────────────────┘
            │                             │
            ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Visualization & Alerting                        │
│                                                                   │
│  • Azure Dashboards        • Workbooks                           │
│  • Alert Rules             • Action Groups                       │
│  • Azure Sentinel (SIEM)   • External SIEM Integration          │
└─────────────────────────────────────────────────────────────────┘
```

### Logged Events

**Control Plane Logs** (Retention: 30-90 days):
- `kube-apiserver`: All API requests
- `kube-controller-manager`: Controller decisions
- `kube-scheduler`: Scheduling decisions
- `kube-audit`: Detailed audit trail (90 days)
- `kube-audit-admin`: Admin audit trail (90 days)
- `cluster-autoscaler`: Scaling events

**Container Logs**:
- Application stdout/stderr
- System pod logs
- Indexed and searchable in Log Analytics

## Design Decisions

### Why Azure CNI over Kubenet?

| Aspect | Azure CNI | Kubenet |
|--------|-----------|---------|
| Pod IP Source | VNet subnet | NAT from node |
| Network Policies | ✅ Native support | ❌ Requires additional setup |
| Azure Integration | ✅ Direct connectivity | ⚠️ Requires NAT |
| IP Address Management | ⚠️ More IP consumption | ✅ IP efficient |
| Performance | ✅ Lower latency | ⚠️ NAT overhead |

**Decision**: Azure CNI for enterprise security and performance requirements.

### Why System-Assigned Identity?

- **No credential management**: Azure manages rotation automatically
- **Least privilege**: Each component gets minimal required permissions
- **Audit trail**: All actions tied to managed identity in Azure AD logs
- **Zero secrets**: No service principal credentials to secure

### Why Multi-Zone by Default?

- **99.95% SLA**: vs 99.5% for single zone
- **Disaster resilience**: Survives datacenter failures
- **Cost**: Minimal overhead (~3% for cross-zone bandwidth)

### Why Private Cluster is Optional?

- **Flexibility**: Different requirements for dev/test vs production
- **Complexity**: Private clusters require ExpressRoute or VPN setup
- **Alternative**: Authorized IP ranges provide security for simpler deployments

## Compliance Mapping

### CIS Benchmark Coverage

| Control | Implementation |
|---------|----------------|
| 5.1.1 - RBAC | Azure AD + Azure RBAC |
| 5.3.1 - Network Policy | Azure Network Policies |
| 5.4.1 - Audit Logging | Diagnostic settings (90-day retention) |
| 5.4.2 - Secrets Management | Key Vault CSI driver |
| 5.6.4 - Policy Enforcement | Azure Policy Add-on |

### NIST 800-53 Controls

| Control Family | AKS Implementation |
|----------------|-------------------|
| AC (Access Control) | AAD + RBAC + local accounts disabled |
| AU (Audit) | Control plane logs + Container Insights |
| SC (System Communications) | Network policies + TLS everywhere |
| SI (System Integrity) | Defender for Containers + Policy |

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-27  
**Maintained By**: Platform Engineering Team
