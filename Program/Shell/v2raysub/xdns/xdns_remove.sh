#!/bin/bash
echo "removing rules"
sudo iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-port 5300
sudo iptables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 5300
sudo ip6tables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5300

echo "remaining rules are"

sudo iptables -t nat -L PREROUTING -n -v --line-numbers
sudo ip6tables -t nat -L PREROUTING -n -v --line-numbers

# stop
xdns_stop