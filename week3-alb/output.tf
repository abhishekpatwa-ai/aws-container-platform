output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.main.dns_name}" # open this in the browser
}

output "listener_arn" {
  value = aws_lb_listener.http.arn # har service ka module isi listener par apna rule lagata hai
}
