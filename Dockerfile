FROM perl:latest

WORKDIR /opt/act
RUN apt-get update \
    && apt-get install -y --no-install-recommends pwgen \
    && apt-get clean && rm -rf /var/cache/apt \
    && mkdir -p /opt/acthome

COPY cpanfile .

# known failure thing
RUN cpanm -n IPC::System::Simple \
    && cpanm --installdeps .

COPY conferences /opt/acthome/conferences
COPY wwwdocs     /opt/acthome/wwwdocs
COPY templates   /opt/acthome/templates
COPY . .


CMD [ "plackup", "app.psgi" ]
