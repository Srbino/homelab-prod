#!/bin/bash

# Vytvoření adresářů pro přímé nasazení
mkdir -p nginx-ingress
mkdir -p argocd-ingress

# Vytvoření základního HelmRepository manifestu pro NGINX Ingress Controller
cat <<EOF > nginx-ingress/Chart.yaml
apiVersion: v1
kind: HelmRepository
metadata:
  name: nginx-ingress
  namespace: argocd
spec:
  url: https://kubernetes.github.io/ingress-nginx
EOF

# Vytvoření hodnotového souboru pro NGINX Ingress Controller
cat <<EOF > nginx-ingress/values.yaml
controller:
  service:
    type: NodePort
    externalIPs: ["192.168.1.11"]  # Lokální IP adresa Unraid
EOF

# Vytvoření jednoduchého Ingress manifestu pro ArgoCD server
cat <<EOF > argocd-ingress/argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
    - host: argocd.local  # Použijeme lokální doménu nebo IP
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
  tls:
    - hosts:
        - argocd.local
      secretName: argocd-secret  # Název TLS certifikátu
EOF

# Vytvoření applications.yaml pro ArgoCD synchronizaci bez Kustomize
cat <<EOF > applications.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Srbino/homelab-prod.git'
    targetRevision: HEAD
    path: nginx-ingress
  destination:
    server: https://kubernetes.default.svc
    namespace: nginx-ingress
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-ingress
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/Srbino/homelab-prod.git'
    targetRevision: HEAD
    path: argocd-ingress
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "Adresářová struktura a konfigurační soubory byly vytvořeny."