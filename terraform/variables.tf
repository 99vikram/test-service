variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "api-service-cluster"
}

variable "kind_config_path" {
  description = "Path to the Kind configuration file"
  type        = string
  default     = "../charts/kind-config.yaml"
}

variable "helm_chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../charts/api-service"
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "api-service"
}

variable "helm_namespace" {
  description = "Kubernetes namespace for the Helm release"
  type        = string
  default     = "default"
}

variable "helm_values_file" {
  description = "Path to Helm values file (e.g., values-dev.yaml or values-prod.yaml)"
  type        = string
  default     = ""
}

variable "wait_for_cluster" {
  description = "Wait for cluster to be ready before deploying"
  type        = bool
  default     = true
}

