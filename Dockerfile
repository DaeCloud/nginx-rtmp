# Use a base image with necessary build tools
FROM ubuntu:20.04

# Set environment variables
ENV NGINX_VERSION=1.21.6
ENV RTMP_MODULE=https://github.com/arut/nginx-rtmp-module/archive/master.zip
ENV HLS_DIR=/usr/local/nginx/html/stream/hls
ENV NGINX_PATH=/usr/local/nginx

# Install required dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g zlib1g-dev unzip wget && \
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

# Create required directories for HLS and DASH
RUN mkdir -p $HLS_DIR

# Copy the custom nginx.conf to the container (create this file locally)
COPY nginx.conf $NGINX_PATH/conf/nginx.conf

# Expose the necessary ports
EXPOSE 1935 80

# Start Nginx
CMD ["sh", "-c", "$NGINX_PATH/sbin/nginx -g 'daemon off;'"]
