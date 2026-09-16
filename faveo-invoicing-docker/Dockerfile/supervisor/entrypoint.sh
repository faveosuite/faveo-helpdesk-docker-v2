#!/bin/bash
set -e

# Start Supervisor in foreground
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf