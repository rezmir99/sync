# Replace <PORT> with your server listen port (e.g., 9999)

# 1. Bypass connection tracking (conntrack) for the connection port. This is essential.
# This tells the kernel's netfilter to ignore packets on this port for state tracking.
sudo iptables -t raw -A PREROUTING -p tcp --dport 9999 -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport 9999 -j NOTRACK

# 2. Prevent the kernel from sending TCP RST packets that would kill the session.
# This drops any RST packets the kernel tries to send from the connection port.
sudo iptables -t mangle -A OUTPUT -p tcp --sport 9999 --tcp-flags RST RST -j DROP

# # An alternative for rule 2 if issues persist:
# sudo iptables -t filter -A INPUT -p tcp --dport <PORT> -j ACCEPT
# sudo iptables -t filter -A OUTPUT -p tcp --sport <PORT> -j ACCEPT

# To make rules persistent across reboots:
# Debian/Ubuntu: sudo iptables-save > /etc/iptables/rules.v4
# RHEL/CentOS: sudo service iptables save