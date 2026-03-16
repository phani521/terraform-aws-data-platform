output "emr_cluster_id" {
  value       = module.emr.cluster_id
  description = "ID of the EMR cluster"
}

output "emr_cluster_name" {
  value       = module.emr.cluster_name
  description = "Name of the EMR cluster"
}

