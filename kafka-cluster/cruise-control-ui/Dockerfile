FROM nginx:latest

ENV CRUISE_CONTROL_UI_VERSION=0.4.0
ENV NGINX_HOME=/usr/share/nginx/html/

RUN curl -LO https://github.com/linkedin/cruise-control-ui/releases/download/v${CRUISE_CONTROL_UI_VERSION}/cruise-control-ui-${CRUISE_CONTROL_UI_VERSION}.tar.gz; \
    tar xvfz cruise-control-ui-${CRUISE_CONTROL_UI_VERSION}.tar.gz -C ${NGINX_HOME} --strip-components=2; \
    rm -f cruise-control-ui-${CRUISE_CONTROL_UI_VERSION}.tar.gz*; \
    echo "dev,dev,/kafkacruisecontrol/" > "${NGINX_HOME}"static/config.csv;

EXPOSE 9090
