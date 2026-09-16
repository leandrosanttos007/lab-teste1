FROM nginx:1.27-alpine

LABEL org.opencontainers.image.source="https://github.com/leandrosanttos007/lab-teste1"
LABEL org.opencontainers.image.description="Lab de CI/CD com GitOps: build, push e atualização de deployment"

COPY src/ /usr/share/nginx/html/

EXPOSE 80
