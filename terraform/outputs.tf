output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = var.cluster_name
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = try(data.external.kubeconfig.result.kubeconfig, "")
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = try(helm_release.api_service.name, "")
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = try(helm_release.api_service.namespace, "")
}

output "cluster_info" {
  description = "Cluster connection information"
  value       = <<-EOT
    To connect to the cluster, run:
    export KUBECONFIG=${try(data.external.kubeconfig.result.kubeconfig, "$(kind get kubeconfig-path --name ${var.cluster_name})")}
    
    Or use:
    kubectl --kubeconfig=${try(data.external.kubeconfig.result.kubeconfig, "$(kind get kubeconfig-path --name ${var.cluster_name})")} get nodes
    
    To access the frontend service:
    kubectl --kubeconfig=${try(data.external.kubeconfig.result.kubeconfig, "$(kind get kubeconfig-path --name ${var.cluster_name})")} port-forward svc/frontend-external 30080:80
    Then access at http://localhost:30080
  EOT
}

output "frontend_nodeport" {
  description = "NodePort for frontend-external service"
  value       = "30080"
}

