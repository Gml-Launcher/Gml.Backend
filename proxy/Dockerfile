FROM docker.angie.software/angie:1.12.1-templated

ENV GML_PROXY_MODE=external \
    GML_PROXY_DOMAIN=

COPY angie.conf /etc/angie/templates/angie.conf
COPY gml-routes.conf /etc/angie/gml-routes.conf

EXPOSE 80 443
