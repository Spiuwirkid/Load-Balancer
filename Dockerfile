FROM nginx:alpine
COPY web /usr/share/nginx/html
CMD ["sh", "-c", "echo $(hostname) > /usr/share/nginx/html/hostname && nginx -g 'daemon off;'"]
