FROM docker:dind

RUN apk add bash

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

COPY ./create_deb.sh /usr/local/create_deb.sh

ENTRYPOINT ["build_and_test.sh"]

