FROM perl:latest

WORKDIR /opt/act

COPY cpanfile .

# known failure thing
RUN cpanm -n IPC::System::Simple \
    && cpanm --installdeps .
COPY . .

RUN apt-get update && apt-get install -y --no-install-recommends pwgen

CMD [ "plackup", "app.psgi" ]
