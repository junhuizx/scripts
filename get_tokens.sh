#!/usr/bin/env bash

for i in `seq 10000`; do
    if (( i%100 == 0 )) ;then
        echo $i
    fi
    curl -i \
      -H "Content-Type: application/json" \
      -d '
    {
        "auth": {
            "passwordCredentials": {
                "password": "password",
                "username": "admin"
            },
            "tenantName": "admin"
        }
    }' \
      http://192.168.205.60:5000/v2.0/tokens > /dev/null 2>/dev/null
done