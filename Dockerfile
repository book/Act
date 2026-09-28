FROM perl:latest

WORKDIR /opt/act
RUN apt-get update \
    && apt-get install -y --no-install-recommends pwgen \
    && apt-get clean && rm -rf /var/cache/apt \
    && mkdir -p /opt/acthome

COPY cpanfile .

# known failure thing
RUN cpanm --notest IPC::System::Simple \
    && cpanm --notest XML::Atom \
    && cpanm --installdeps .

COPY wwwdocs     /opt/acthome/wwwdocs
COPY templates   /opt/acthome/templates
COPY po          /opt/acthome/po
#bind it at run: COPY conferences /opt/acthome/conferences
COPY . .

ENTRYPOINT [ "/opt/act/docker-entrypoint.sh" ]
CMD [ "plackup", "app.psgi" ]
