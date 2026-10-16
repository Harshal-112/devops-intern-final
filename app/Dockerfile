FROM nginx:1.27-alpine

ARG BUILD_SHA=local

LABEL org.opencontainers.image.title="devops-intern-final"

RUN addgroup -S app \
    && adduser -S -G app app \
    && mkdir -p /tmp/client_temp /tmp/proxy_temp \
       /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp \
    && chown -R app:app /tmp \
    && chown -R app:app /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /tmp/index.html

RUN sed "s/BUILD_SHA_PLACEHOLDER/${BUILD_SHA}/g" \
    /tmp/index.html > /usr/share/nginx/html/index.html \
    && rm /tmp/index.html \
    && chown app:app /usr/share/nginx/html/index.html

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
