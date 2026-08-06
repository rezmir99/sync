#!/bin/bash
iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-port 5300
iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 5300

sudo ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5300

# # remove
# iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-port 5300
# iptables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 5300
