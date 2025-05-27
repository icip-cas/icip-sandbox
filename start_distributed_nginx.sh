NUM_NODES=${NUM_NODES:-1}

# Set a while loop, and check if number of files server/addr_* larger than number of nodes
while [ $(ls server/addr_* | wc -l) -lt ${NUM_NODES} ]; do
    echo "Waiting for all ${NUM_NODES} nodes to be ready..."
    sleep 5
done

# Write to server/nginx.conf
# Set worker_connections as the maximum value, which is the number of open files
printf "events {\n    worker_connections  $(ulimit -n);\n}\nhttp {\n    upstream myapp1 {\n" > server/nginx.conf

addr_list=$(ls server/addr_*)
for addr_file in ${addr_list}; do
    # Read the address from the file
    addr=$(cat ${addr_file})
    # Check if the address is working
    if ! curl -s "http://${addr}" --max-time 2; then
        echo "Address ${addr} is not working, remove it from the list"
        rm ${addr_file}
        continue
    fi
    # Write the address to the nginx config file
    printf "        server ${addr} max_fails=3 fail_timeout=30s;\n" >> server/nginx.conf
    echo "Address ${addr} is working, add it to the list"
done

printf "    }\n    server {\n        listen 8081;\n        listen [::]:8081;\n        server_name localhost;\n\n        location /{\n            proxy_pass http://myapp1;\n        }\n    }\n    client_max_body_size 128M;\n    fastcgi_read_timeout 600;\n    proxy_read_timeout 600;\n}" >> server/nginx.conf

echo "Nginx config file generated at server/nginx.conf"
cat server/nginx.conf
echo ""
echo "Starting Nginx..."
# If nginx is not already running, start it; otherwise, reload the config
nginx_pid=$(ls /var/run/nginx.pid 2>/dev/null)
if [ -z "${nginx_pid}" ]; then
    echo "Nginx is not running, starting it..."
    sudo nginx -c $(pwd)/server/nginx.conf
else
    echo "Nginx is already running, reloading the config..."
    sudo nginx -s reload -c $(pwd)/server/nginx.conf
fi
echo "Nginx started, listening on port 8081"
echo "You can access the server at http://localhost:8081"
