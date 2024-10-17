# Use a base image with necessary build tools
FROM ubuntu:20.04

# Set environment variables
ENV NGINX_VERSION=1.21.6
ENV RTMP_MODULE=https://github.com/arut/nginx-rtmp-module/archive/master.zip
ENV HLS_DIR=/usr/local/nginx/html/stream/hls
ENV NGINX_PATH=/usr/local/nginx
ENV NGINX_CONF_DIR=$NGINX_PATH/conf
ENV NGINX_HTPASSWD_PATH=$NGINX_CONF_DIR/.htpasswd

# Variables for basic auth (these will be set at runtime)
ENV BASIC_AUTH_USERNAME=
ENV BASIC_AUTH_PASSWORD=

# Install required dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g zlib1g-dev unzip wget apache2-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install Nginx with the RTMP module
RUN cd /usr/local/src && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    wget $RTMP_MODULE && \
    tar -zxvf nginx-$NGINX_VERSION.tar.gz && \
    unzip master.zip && \
    cd nginx-$NGINX_VERSION && \
    ./configure --add-module=../nginx-rtmp-module-master --with-http_ssl_module && \
    make && \
    make install

# Create required directories for HLS
RUN mkdir -p $HLS_DIR

# Copy the custom nginx.conf to the container (this will use basic auth)
COPY nginx.conf $NGINX_CONF_DIR/nginx.conf

# Expose the necessary ports
EXPOSE 1935 80

# Script to create the .htpasswd file and start Nginx
RUN echo '#!/bin/bash\n' > /start.sh && \
    echo 'if [[ -z "$BASIC_AUTH_USERNAME" || -z "$BASIC_AUTH_PASSWORD" ]]; then' >> /start.sh && \
    echo '  echo "Basic Auth Username or Password not set!"' >> /start.sh && \
    echo '  exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo "htpasswd -bc $NGINX_HTPASSWD_PATH \$BASIC_AUTH_USERNAME \$BASIC_AUTH_PASSWORD" >> /start.sh && \
    echo "$NGINX_PATH/sbin/nginx -g 'daemon off;'" >> /start.sh && \
    chmod +x /start.sh

# Start Nginx with basic auth
CMD ["/start.sh"]
