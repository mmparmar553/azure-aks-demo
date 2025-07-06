# Security Implementation Guide

## 🛡️ Security Architecture Overview

This AKS demo implements defense-in-depth security with multiple layers:

1. **Infrastructure Security** - Private cluster, private ACR, network segmentation
2. **Service Mesh Security** - Istio mTLS, authorization policies
3. **Kubernetes Security** - RBAC, network policies, pod security
4. **Container Security** - Non-root, read-only filesystem, capability dropping
5. **Monitoring Security** - Audit logging, security dashboards

## 🔐 Istio Service Mesh Security

### mTLS Configuration

**Strict mTLS** is enforced across all services:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: nginx-demo
spec:
  mtls:
    mode: STRICT
```

**Benefits:**
- All pod-to-pod communication is encrypted
- Automatic certificate management
- Identity-based authentication
- Protection against man-in-the-middle attacks

### Authorization Policies

Fine-grained access control:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: nginx-authz
  namespace: nginx-demo
spec:
  selector:
    matchLabels:
      app: nginx-frontend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
  - to:
    - operation:
        methods: ["GET", "POST"]
```

**Features:**
- Service-to-service authorization
- HTTP method restrictions
- Principal-based access control
- Deny-by-default security model

## 🔒 Kubernetes Security

### Network Policies

Micro-segmentation at the network level:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nginx-netpol
  namespace: nginx-demo
spec:
  podSelector:
    matchLabels:
      app: nginx-frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: istio-system
    ports:
    - protocol: TCP
      port: 80
```

**Benefits:**
- Default deny all traffic
- Explicit allow rules only
- Namespace isolation
- Protocol and port restrictions

### Pod Security Context

Hardened container runtime:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 101
  fsGroup: 101
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

**Security Features:**
- Non-root execution (UID 101)
- Read-only root filesystem
- No privilege escalation
- All capabilities dropped
- Proper file system permissions

### RBAC (Role-Based Access Control)

Least privilege access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: nginx-demo
  name: nginx-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
```

**Principles:**
- Minimal required permissions
- Namespace-scoped roles
- Service account binding
- Regular access reviews

## 🏗️ Infrastructure Security

### Private AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
  }
}
```

**Security Benefits:**
- No public API server endpoint
- Private node communication
- Azure CNI with network policies
- Controlled access via bastion host

### Private Container Registry

```hcl
resource "azurerm_container_registry" "acr" {
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
}
```

**Features:**
- No public internet access
- Azure service integration
- Image vulnerability scanning
- Content trust and signing

### Network Security Groups

```hcl
resource "azurerm_network_security_group" "aks_nsg" {
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_address_prefix      = "*"
  }
}
```

**Controls:**
- Explicit allow rules only
- Port-specific access
- Protocol restrictions
- Source IP filtering

## 🔍 Security Monitoring

### Azure Defender for Kubernetes

```hcl
microsoft_defender {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
}
```

**Capabilities:**
- Runtime threat detection
- Vulnerability assessments
- Security recommendations
- Compliance monitoring

### Audit Logging

```hcl
oms_agent {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
}
```

**Audit Trail:**
- API server audit logs
- Resource access tracking
- Security event monitoring
- Compliance reporting

## 🧪 Security Validation

### mTLS Verification

```bash
# Check mTLS status
istioctl proxy-config cluster deployment/nginx-frontend.nginx-demo

# Verify certificates
istioctl proxy-config secret deployment/nginx-frontend.nginx-demo
```

### Network Policy Testing

```bash
# Test blocked communication
kubectl run test-pod --rm -i --tty --image=busybox -- /bin/sh
# Try to access services from unauthorized pod
```

### Security Scanning

```bash
# Scan container images
az acr check-health --name <acr-name>

# Check for vulnerabilities
kubectl get vulnerabilityreports -A
```

### RBAC Validation

```bash
# Test service account permissions
kubectl auth can-i --list --as=system:serviceaccount:nginx-demo:nginx-sa -n nginx-demo

# Verify unauthorized access is blocked
kubectl auth can-i create pods --as=system:serviceaccount:nginx-demo:nginx-sa -n nginx-demo
```

## 🚨 Security Incident Response

### Detection

1. **Monitor Azure Defender alerts**
2. **Check Istio access logs**
3. **Review audit logs in Log Analytics**
4. **Monitor network policy violations**

### Response Procedures

1. **Isolate affected workloads**
   ```bash
   kubectl patch deployment nginx-frontend -p '{"spec":{"replicas":0}}'
   ```

2. **Block network access**
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-all
     namespace: nginx-demo
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   EOF
   ```

3. **Collect forensic data**
   ```bash
   kubectl logs deployment/nginx-frontend -n nginx-demo --previous
   kubectl describe pod <pod-name> -n nginx-demo
   ```

## 📋 Security Checklist

### Pre-Deployment
- [ ] Private cluster configuration verified
- [ ] Network policies defined
- [ ] RBAC roles configured
- [ ] Container security context set
- [ ] Image vulnerability scanning enabled

### Post-Deployment
- [ ] mTLS verification completed
- [ ] Network policy testing passed
- [ ] RBAC validation successful
- [ ] Security monitoring configured
- [ ] Incident response procedures documented

### Ongoing Maintenance
- [ ] Regular security updates applied
- [ ] Vulnerability scans performed
- [ ] Access reviews conducted
- [ ] Security policies updated
- [ ] Compliance reports generated

## 🔧 Security Hardening Recommendations

### Additional Measures

1. **Pod Security Standards**
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: nginx-demo
     labels:
       pod-security.kubernetes.io/enforce: restricted
       pod-security.kubernetes.io/audit: restricted
       pod-security.kubernetes.io/warn: restricted
   ```

2. **OPA Gatekeeper Policies**
   ```yaml
   apiVersion: templates.gatekeeper.sh/v1beta1
   kind: ConstraintTemplate
   metadata:
     name: k8srequiredsecuritycontext
   ```

3. **Falco Runtime Security**
   ```bash
   helm install falco falcosecurity/falco \
     --namespace falco-system \
     --create-namespace
   ```

4. **Image Policy Webhook**
   ```yaml
   apiVersion: admissionregistration.k8s.io/v1
   kind: ValidatingAdmissionWebhook
   ```

## 📚 Security Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Istio Security](https://istio.io/latest/docs/concepts/security/)
- [Azure AKS Security](https://docs.microsoft.com/en-us/azure/aks/concepts-security)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

---

**🛡️ Security is a journey, not a destination. Stay vigilant!** 🔐
