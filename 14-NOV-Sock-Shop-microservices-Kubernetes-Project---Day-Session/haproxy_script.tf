/* locals {
  haproxy_user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y

  echo "*********This runs as the root and disables StrictHostChecking********"
  sudo bash -c 'echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'

  sudo apt-get install haproxy -y
  cat <<EOT>> /etc/haproxy/haproxy.cfg
  frontend fe-apiserver
    bind 0.0.0.0:6443
    mode tcp
    option tcplog
    default_backend be-apiserver
  
  backend be-apiserver
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

        server master1 ${data.aws_instance.Master01_IP_address.private_ip}:6443 check
        server master2 ${data.aws_instance.Master02_IP_address.private_ip}:6443 check
  EOT
  systemctl restart haproxy
  systemctl status haproxy
  
  echo "****************Change Hostname(IP) to something readable**************"
  sudo hostnamectl set-hostname LoadBalancer
  sudo reboot
  EOF
} */