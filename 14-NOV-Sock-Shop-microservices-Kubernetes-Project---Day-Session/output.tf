output "Master01_node" {
  value = aws_instance.Master01_node.private_ip
}

output "Master02_node" {
  value = aws_instance.Master02_node.private_ip
}

output "Master03_node" {
  value = aws_instance.Master03_node.private_ip
}


output "Worker01_node" {
  value = aws_instance.Worker01_node.private_ip
}

output "Worker02_node" {
  value = aws_instance.Worker02_node.private_ip
}

output "loadbalancer" {
  value = aws_instance.loadbalancer.public_ip
}

/* output "Ansible_Node" {
  value = aws_instance.Ansible_Node.private_ip
} */
/* output "ALB_DNS" {
  value = aws_lb.ssmk-lb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.ssmk-tg.arn
}

output "PLB_DNS" {
  value = aws_lb.prom-lb.dns_name
}

output "Prometheus_target_group_arn" {
  value = aws_lb_target_group.prom-tg.arn
}

output "GLB_DNS" {
  value = aws_lb.graf-lb.dns_name
}

output "Grafana_target_group_arn" {
  value = aws_lb_target_group.graf-tg.arn
}

output "nameservers" {
    value = aws_route53_zone.ssmk_route53.name_servers
} */
