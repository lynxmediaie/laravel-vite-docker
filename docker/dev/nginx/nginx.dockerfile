FROM nginx:stable-alpine

# environment arguments
ARG UID=1000
ARG GID=1000
ARG USER=appuser

ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}

# Dialout group in alpine linux conflicts with MacOS staff group's gid, whis is 20. So we remove it.
RUN delgroup dialout

# Creating user and group
RUN addgroup -g ${GID} --system ${USER} || true
RUN adduser -G ${USER} --system -D -s /bin/sh -u ${UID} ${USER} || true

# Modify nginx configuration to use the new user's priviledges for starting it.
RUN sed -i "s/user nginx/user '${USER}'/g" /etc/nginx/nginx.conf

# Copies nginx configurations to override the default.
ADD *.conf /etc/nginx/conf.d/

# Make html directory
RUN mkdir -p /var/www/html