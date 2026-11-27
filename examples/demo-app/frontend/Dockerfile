# nginx-unprivileged: same nginx, runs as uid 101 and listens on 8080.
FROM nginxinc/nginx-unprivileged:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
USER 101
