FROM perl:latest

WORKDIR /opt/act

COPY cpanfile .

# known failure thing
RUN cpanm -n IPC::System::Simple \
    && cpanm --installdeps .
COPY . .

#RUN [ "plackup", "app.psgi" ]
