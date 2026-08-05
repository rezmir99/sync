#!/bin/bash
service_name=$1

sudo systemctl enable "$service_name"
sudo systemctl start "$service_name"
