#!/bin/bash

ls -la /opt/unbound/etc

while true; do 
    if [ -f /opt/unbound/etc/unbound/unbound_control.key ]; then 
        break;
    else 
        echo "Waiting for /opt/unbound/etc/unbound/unbound_control.key" && sleep 1;
    fi;
done

exec /opt/unbound_exporter  -unbound.ca  /opt/unbound/etc/unbound/unbound_server.pem \
                            -unbound.cert /opt/unbound/etc/unbound/unbound_control.pem \
                            -unbound.key /opt/unbound/etc/unbound/unbound_control.key
