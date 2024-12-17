#PROD build attempt
FROM node:16.20.2 AS install
WORKDIR /usr/src/app
COPY . .
RUN rm package-lock.json && npm install
RUN npx gulp deploy

FROM nginx:1.23-alpine
COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/conf.json.template /
COPY docker/config_env_subst.sh /docker-entrypoint.d/30_config_env_subst.sh
RUN set -eux; \
    apk update; \
    apk add --no-cache --virtual .build-deps \
       subversion; \
    apk add \
       bash; \
    mkdir taiga
COPY --from=install /usr/src/app/dist /taiga/dist
RUN set -eux; \
    mv /conf.json.template taiga/dist/; \
    chmod +x /docker-entrypoint.d/30_config_env_subst.sh; \
    # Install taiga-front contribs
    mkdir /taiga/dist/plugins; \
    cd /taiga/dist/plugins; \
    # Slack
    wget https://github.com/taigaio/taiga-contrib-slack/archive/6.8.0.zip -O source.zip; \
    unzip -j source.zip "taiga-contrib-slack-6.8.0/front/dist/*" -d slack; \
    rm source.zip; \
    # Github
    wget http://github.com/taigaio/taiga-contrib-github-auth/archive/6.8.0.zip -O source.zip; \
    unzip -j source.zip "taiga-contrib-github-auth-6.8.0/front/dist/*" -d github-auth; \
    rm source.zip; \
    # Gitlab
    wget http://github.com/taigaio/taiga-contrib-gitlab-auth/archive/6.8.0.zip -O source.zip; \
    unzip -j source.zip "taiga-contrib-gitlab-auth-6.8.0/front/dist/*" -d gitlab-auth; \
    rm source.zip; \
    cd /; \
    # Remove unused dependencies
    apk del --no-cache .build-deps; \
    # Ready for nginx
    mv /taiga/dist/* /usr/share/nginx/html; \
    rm -rf /taiga /var/cache/apk/*
