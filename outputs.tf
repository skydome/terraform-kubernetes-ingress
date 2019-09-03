output "load_balancer_ip" {
 description = "IP address of the load balancer for nginx ingress controllers"
 value       = "${kubernetes_service.ingress_nginx.*.load_balancer_ingress.0.ip}"
}
