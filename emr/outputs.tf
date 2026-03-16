output "emr_cluster_id" {
  value = module.emr.aws_emr_cluster_id
  description = "ID of the EMR cluster (adjust if you add output in module)"
}
