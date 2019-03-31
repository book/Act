FROM perl:latest

WORKDIR /opt/act
RUN apt-get update \
    && apt-get install -y --no-install-recommends pwgen \
    && apt-get clean && rm -rf /var/cache/apt

COPY cpanfile .

# known failure thing
RUN cpanm -n IPC::System::Simple \
    && cpanm --installdeps .
COPY . .


CMD [ "plackup", "app.psgi" ]
