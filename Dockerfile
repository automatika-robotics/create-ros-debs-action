FROM docker:dind

RUN apk add bash

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

COPY ./create_deb.sh /create_deb.sh

ENTRYPOINT ["entrypoint.sh"]

