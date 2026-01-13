Write-Host "---Verifying if DNS resolution is working or not---"
$result = wsl -e curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 https://ghcr.io 2>$null
if ($result -match "^[23]\d{2}$") { # 200-299 = Success; 300-399 = Redirect
    Write-Host "DNS resolution is working (HTTP $result), no fix needed"
    exit 0
}
Write-Host "DNS resolution failed (HTTP $result), applying fix"

Write-Host "---Current configuration status---"
wsl -e sudo cat /etc/wsl.conf

Write-Host "---Changing default DNS behavior---"
# appends a [network] entry if it doesn't exist already
wsl -e sudo bash -c "grep -q '\[network\]' /etc/wsl.conf 2>/dev/null || printf '\n[network]\n' >> /etc/wsl.conf; grep -q 'generateResolvConf' /etc/wsl.conf || echo 'generateResolvConf = false' >> /etc/wsl.conf" 
wsl -e sudo cat /etc/wsl.conf 

Write-Host "---Specifying a more reliable DNS server---"
wsl -e sudo rm -f /etc/resolv.conf 
wsl -e sudo bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" 
wsl -e sudo cat /etc/resolv.conf 

Write-Host "---Verifying if DNS resolution is working after the applied fix---"
$result = wsl -e curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 https://ghcr.io 2>$null
if ($result -match "^[23]\d{2}$") { # 200-299 = Success; 300-399 = Redirect
    Write-Host "DNS resolution is working (HTTP $result), the fix worked"
    exit 0
}
Write-Host "DNS resolution failed (HTTP $result), the fix did not work"