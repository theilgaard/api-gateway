FROM openresty/openresty:alpine

# Install required dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache curl bash

# Set working directory
WORKDIR /usr/local/openresty/nginx

# Copy Nginx configuration files
COPY nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx/conf.d/ /usr/local/openresty/nginx/conf/conf.d/
COPY nginx/lua/ /usr/local/openresty/nginx/conf/lua/

# Copy scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Expose the port Nginx will run on
EXPOSE 80

# Start OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]