# verify DNS resolution is not working
wsl curl -I https://ghcr.io 

# show current configuration status
wsl sudo cat /etc/wsl.conf

# change default dns behavior
wsl sudo sh -c 'cat <<EOT > /etc/wsl.conf  
[network]   
generateResolvConf = false 
EOT' 

# show configuration changes
wsl sudo cat /etc/wsl.conf 

# specify a more reliable DNS server
wsl sudo rm -f /etc/resolv.conf 
wsl sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf' 

# verify DNS resolution should work now
wsl curl -I https://ghcr.io 