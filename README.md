# MVS/CE Docker Image

```
     888b     d888 888     888  .d8888b.        d88P  .d8888b.  8888888888
     8888b   d8888 888     888 d88P  Y88b      d88P  d88P  Y88b 888
     88888b.d88888 888     888 Y88b.          d88P   888    888 888
     888Y88888P888 Y88b   d88P  "Y888b.      d88P    888        8888888
     888 Y888P 888  Y88b d88P      "Y88b.   d88P     888        888
     888  Y8P  888   Y88o88P         "888  d88P      888    888 888
     888   "   888    Y888P    Y88b  d88P d88P       Y88b  d88P 888
     888       888     Y8P      "Y8888P" d88P         "Y8888P"  8888888888
```

This is the docker container for the MVS/CE mainframe. 
This images come with Hercules Hyperion and the current image of MVS/CE. https://github.com/MVS-sysgen/sysgen

## Application Setup

MVS/CE makes use of a few folders, for this image these have been converted to volumes:

| Path          | Description                          |
|:-------------:|--------------------------------------|
| `/config`     | Location of the hercules config file |
| `/printers`   | Printer file output                  |
| `/punchcards` | Punchcard file output                |
| `/logs`       | Hercules and MVS logs                |
| `/dasd`       | Hercules DASD (disk) images          |
| `/certs`      | TLS pem file (certificates) location |

All of these volumes are optional. When this docker image is provisioned it
will check for the presence of `local.cnf` in `/config`, `ftp.pem` and `3270.pem`
in `/certs` and all the DASD images that come with MVS/CE in `/dasd`. If any of
those files are missing they will be copied from the defauls. Therefore if you
mess up your certs, config or any of the dasd files, simply deleting them or
renaming them will cause them to be rebuilt the next time this container
is provisioned/reset.

Multiple ports are exposed:

| Port | Description                            |
|:----:|----------------------------------------|
| 3221 | Encrypted FTPD Server. See notes below |
| 3223 | Encrypted TN3270. See notes below      |
| 3270 | Unencrypted TN3270                     |
| 3505 | ASCII JES2 listener                    |
| 3506 | EBCDIC JES2 listener                   |
| 8888 | Hercules web server. See notes below   |


**Notes:**

Port `3221` is an encrypted FTP server port. The FTPD server is not installed by
default. To install log on with TSO then run the command `RX MVP INSTALL FTPD`.
Once installed use the hercules web console to start the FTP server with: `/S FTPD`.
The TLS certificate used is stored in `/certs/ftp.pem` but this certificate is 
**self signed**. You can replace if with your own cert.

Port `3223` is an encrypted 3270 server. The TLS certificate used is stored in
`/certs/3270.pem` but this certificate is **self signed**. You can replace if
with your own cert using the same file name.

Port `8888` is the hercules web console. This server requires authentication
to access it. By default the username and password is `hercules`. To change it
set the environment variable `HUSER` and `HPASS` to a username and password of
your choice.

## Users

| Username  | Password |
|:---------:|:--------:|
| IBMUSER   | SYS1     |
| MVSCE01   | CUL8TR   |
| MVSCE02   | PASS4U   |

## Environment variables

* `HUSER` the hercules web server auth username
* `HPASS` the hercules web server auth password

## Usage

Here are some example snippets to help you get started creating a container.

```
docker run -d \
  --name=mvsce \
  -e HUSER=docker \
  -e HPASS=docker \
  -p 2121:3221 \
  -p 2323:3223 \
  -p 3270:3270 \
  -p 3505:3505 \
  -p 3506:3506 \
  -p 8888:8888 \
  -v /opt/docker/mvsce:/config \
  -v /opt/docker/mvsce/printers:/printers \
  -v /opt/docker/mvsce/punchcards:/punchcards \
  -v /opt/docker/mvsce/logs:/logs \
  -v /opt/docker/mvsce/dasd:/dasd \
  -v /opt/docker/mvsce/certs:/certs \
  --restart unless-stopped \
  mainframed767/mvsce
```

## Parameters

Container images are configured using parameters passed at runtime (such as
those above). These parameters are separated by a colon and indicate 
`<external>:<internal>` respectively. For example, `-p 8080:80` would expose
port `80` from inside the container to be accessible from the host's IP on port
`8080` outside the container.


| Parameter         | Function                             |
|:-----------------:|--------------------------------------|
| `-e HUSER=docker` | Hercules HTTP auth user              |
| `-e HPASS=docker` | Hercules HTTP auth password          |
| `-p 3221`           | TLS FTP port                         | 
| `-p 3223`           | TLC TN3270 Port                      |
| `-p 3270`         | Unencrypted 3270 port                |
| `-p 3505`         | ASCII JES2 listener port             |
| `-p 3506`         | EBCDIC JES2 listener port            |
| `-p 8888`         | HTTP server port                     |
| `-v /config`      | Local path for Hercules config file  |
| `-v /printers`    | Local path for MVS/CE printers       |
| `-v /punchcards`  | Local path for MVS/CE punchcards     |
| `-v /logs`        | Local path for MVS/CE logs           |
| `-v /dasd`        | Local path for MVS/CE DASD           |


## Building the container

To build a new docker image do the following:

* Run `docker build --build-arg RELEASE_VERSION=<V#R#M#> --tag "mainframed767/mvsce:<version>" .` to build the container, replace <version> and <V#R#M#> with a version
* Push to docker hub
