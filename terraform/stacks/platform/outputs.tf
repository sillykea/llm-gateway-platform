output "argocd_ui" {
  description = "How to reach the Argo CD UI."
  value       = "kubectl -n argocd port-forward svc/argocd-server 8080:80, then open http://localhost:8080 (user admin, password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
}
