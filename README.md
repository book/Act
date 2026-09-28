# Act - A conference tool

Welcome to the repository of Act. This README will hopefully help you to get
going with development of Act or to create your own conference in a dummy
playground on your local machine. This version of Act uses psgi instead of
Apache.

# Running the development environment

Depending on your preferences, there are two ways to setup and run an
environment for developing and testing Act.  If you prefer to run
tests on your desktop, on a dedicated virtual machine or bare metal,
you should check out
[act-starter-debian](https://https://github.com/act-psgi/act-starter-debian).
This is a set of shell procedures which creates a complete Act
environment including a PostgreSQL database and a source checkout, and
is regularly tested to work on bare [Vagrant](vagrantup.com/) boxes
for current Debian and Ubuntu systems.

If you prefer a [dockerized](http://www.docker.com/) environment with
separate containers for Act, the database, and a mail server: This is
already included in the Act repository.  Read on how to setup and
maintain it.

## TL;DR

```
docker-compose up
```

Create your conference in the `conferences` directory. A somewhat working
example can be found in the `conferences/demo` directory. More inspiration can
be found on the Github page of
[Act-Conferences](https://github.com/Act-Conferences).

## The longer version

Act uses [docker](http://www.docker.com/) to manage development
environments that are the same for every developer. To create a new
environment, you first need to install `docker` and `docker-compose`.
For docker please follow the installation instructions as found on the
[docker documenation page](https://docs.docker.com/engine/installation/).
The minimum versions we use for testing are Docker version 19.03.6 and
docker-compose version 1.17.1.

Docker is very disk consuming, make sure you have sufficient space
somewhere for docker to use. One can tweak the default `/var/lib/docker`
to be elsewhere. For more information see the
[docker forums](https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169).

You can reclaim disk space from old (unused) container images using:

`docker image prune`

You can (re)create all the containers by running this:
```
# Only rebuild act container
./dev-bin/docker-maintenance.sh act

# Rebuild all the containers
./dev-bin/docker-maintenance.sh
```

If you prefer `podman` over `docker`, the `Dockerfile` and `docker-compose.yml`
are compliant:

```
podman-compose up
```

## Generate configuration files

While `docker-maintenance.sh` already generates all the configuration files
that are needed for you, you could also opt to run
`./dev-bin/generate-config.sh` manually.

## Start your docker

You can now start your development environment by running:

```
$ docker-compose up
# or...
$ docker-compose start
# or...
$ podman-compose up
# or...
```

You can now connect to the development environment on http://localhost:5000/.

## Override the docker-compose.yml file

In case you want to override certain `docker-compose.yml` entries but you
don't want to check them you can make use of the
`docker-compose.overide.yml` file, you can find a working example in
`docker-compose.overide.dist`.

After editting this file you need to recreate the containers:
```
docker-compose rm -s -f <container>

docker-compose up --no-start <container>
docker-compose start <container>

# or
./dev-bin/docker-maintenance.sh <container>

# Or just
docker-compose up -d <container>
```

# Docker infrastructure

This repo uses docker to do things. It is now possible to create a test
environment in Docker and test things easily and it should be the same for
every developer and conference organiser. Although we may need to publish the
build artifact to a registry for 100% equality.

## Docker compose

The docker compose file determines the services that need to run in order for
Act to fully work. The default `docker-compose.yml` will start the container as
is defined in the Dockerfile. It does mount some directories and files into it
so you can easily add and edit your conference files.

## Two database servers

To make loading the databases a bit easier on the Docker side I've chosen to
create two database servers, one for Act itself and the other for the wiki.
Both can be accessed by the `act` user with the password `act123`. The wiki
database is named `act_wiki` and the act database is named `act`.

Act itself will do version checking on the database schema, for Docker I've
chosen to disable this in the act.ini file (for now). You can set the
`version_check` parameter to `0` and then it won't check the version. This
feature may or may not be implemented to the master branch, but it is here now.

The files present in `db/{act,wiki}/initial` are used to setup your database on
the first run. See the documentation of the Postgres image on [Docker
hub](https://hub.docker.com/_/postgres). After you have started your containers
for the first time all these files will be ignored by Postgres. Any changes in
these loading scripts will require you to remove the various database volumes.
The snippet below might help you clean things up, but all the data in your
databases will be lost. Use with care.

```
docker-compose stop act-db act-wiki-db
docker container ps -a | grep act | grep db | awk '{print $1}' | \
xargs -r docker container rm
docker volume ls | grep act | grep db | awk '{print $NF}' | \
xargs -r docker volume rm
```

## If prefer one database server

If you prefer a single container for both Act DB and wiki DB, use
`docker-compose-1db.yml` instead:

```
docker-compose -f docker-compose-1db.yml up
# ...
docker-compose -f docker-compose-1db.yml down
```

Note that at first run, when the DBs need to be initialized, Act may 
crashes as it tries to interact with a DB that is not ready yet.
If it happens, just stop and restart the pod:

```
docker-compose -f docker-compose-1db.yml down
docker-compose -f docker-compose-1db.yml up
# or...
podman-compose -f docker-compose-1db.yml down
podman-compose -f docker-compose-1db.yml up
```

### Local access

The databases can be accessed from your local machine if you use an override
(found in `docker-compose.override.dist`) by using `psql -U act -h localhost`
for act itself and `psql -U act -h localhost -p 5433` for the wiki.
Other port numbers can be used, but is left as an exercise for the reader.

## Plack

Plack is running without any kind of webserver frontend. Which means it deals
with all the webserving logic that one would require to serve static files.

You can enable debugging for Plack by using the `ACT_DEBUG` environment
variable. It is injected into Plack's debug module and you can define all your
debug panels from this environment variable. See the
`docker-compose.override.dist` for more information.

TODO: Create a setup which has Apache and/or NginX in front of Plack by using
FCGI or other means.

## Files

Files can be uploaded by the user and these files go into `/opt/filestore`.
This location is a volume, so data doesn't get lost between restarts of the
container. More work is required if people want to use Swift, S3 or any other
kind of remote file storage.

## Mail

Act sends out mail to users, therefore a simple mailserver has been created
based on the mailhog image. This mailserver has webUI available on port
http://localhost:8025 so you can see what kind of mails you have send. It uses
a memory backend so all the mails are lost after a restart.

Technical documentation about Act is available in the directory
lib/Act/Manual.  The pod files can be nicely read in GitHub, and even
more comfortably online from our demo server at
https://act-test.plix.at/manual/Manual.html.
