# Act - A conference tool

Welcome to the repository of Act. This README will hopefully help you to get
going with development of Act or to create your own conference in a dummy
playground on your local machine.

# Running the development environment

## TL;DR

```
./dev-bin/docker-maintenance.sh
```

## The longer version

Act uses [docker](http://www.docker.com/) to manage development
environments that are the same for every developer. To create a new
environment, you first need to install `docker` and `docker-compose`.
For docker please follow the installation instructions as found on the
[docker documenation page](https://docs.docker.com/engine/installation/).

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

## macOS

For macOS it is advised that you configure docker to to have at least 8Gb
of memory. Otherwise you may end up with build errors.

## Generate configuration files

While `docker-maintenance.sh` already generates all the configuration files
that are needed for you, you could also opt to run
`./dev-bin/generate-config.sh` manually.

## Start your docker

You can now start your development environment by running:

```
$ docker-compose up
# or..
$ docker-compose start
```

You can connect to the development environment on http://localhost:5000/ now.

## Override the docker-compose.yml file

In case you want to override certain `docker-compose.yml` entries but you
don't want to check them you can make use of the
`docker-compose.overide.yml` file, you can find a working example in
`docker-compose.overide.example`.

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
