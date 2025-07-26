FROM nginx:1.25-alpine

# Remove a configuração padrão do Nginx.
RUN rm /etc/nginx/conf.d/default.conf


COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia o código do frontend (o arquivo index.html) para a pasta que o Nginx serve.
COPY index.html /usr/share/nginx/html