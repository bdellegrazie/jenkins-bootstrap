FROM debian:buster-backports as build

RUN sed -i -e '/^#/d' -e 's/^deb \(.*\)/deb \1\ndeb-src \1/' /etc/apt/sources.list && \
  sed -i -e '/^#/d' -e 's/^deb \(.*\)/deb \1\ndeb-src \1/' /etc/apt/sources.list.d/backports.list

RUN adduser --uid 1000 --gecos "Build User,,," --disabled-password --disabled-login build

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y build-essential fakeroot devscripts nano && \
    DEBIAN_FRONTEND=noninteractive apt-get -t buster-backports install -q -y ca-certificates libssl-dev openssl squid && \
    DEBIAN_FRONTEND=noninteractive apt-get -t buster-backports build-dep -q -y squid

USER build

WORKDIR /home/build

RUN DEBIAN_FRONTEND=noninteractive apt-get -t buster-backports source squid

COPY squid.patch /home/build/

WORKDIR /home/build/squid-4.11

RUN patch -u /home/build/squid.patch

#RUN apt-get -q update && \
# DEBIAN_FRONTEND=noninteractive apt-get -t buster-backports install -qy --no-install-recommends \
#   ca-certificates \
#   openssl \
#   squid

# Usage: squid [-cdzCFNRVYX] [-n name] [-s | -l facility] [-f config-file] [-[au] port] [-k signal]
#    -h | --help       Print help message.
#    -v | --version    Print version details.
#
#       -a port   Specify HTTP port number (default: 3128).
#       -d level  Write debugging to stderr also.
#       -f file   Use given config-file instead of
#                 /etc/squid/squid.conf
#       -k reconfigure|rotate|shutdown|restart|interrupt|kill|debug|check|parse
#                 Parse configuration file, then send signal to
#                 running copy (except -k parse) and exit.
#       -n name   Specify service name to use for service operations
#                 default is: squid.
#       -s | -l facility
#                 Enable logging to syslog.
#       -u port   Specify ICP port number (default: 3130), disable with 0.
#       -z        Create missing swap directories and then exit.
#       -C        Do not catch fatal signals.
#       -D        OBSOLETE. Scheduled for removal.
#       -F        Don't serve any requests until store is rebuilt.
#       -N        Master process runs in foreground and is a worker. No kids.
#       --foreground
#                 Master process runs in foreground and creates worker kids.
#       --kid role-ID
#                 Play a given SMP kid process role, with a given ID. Do not use
#                 this option. It is meant for the master process use only.
#       -R        Do not set REUSEADDR on port.
#       -S        Double-check swap during rebuild.
#       -X        Force full debugging.
#       -Y        Only return UDP_HIT or UDP_MISS_NOFETCH during fast reload.

EXPOSE 3128 3130/udp

VOLUME [ "/var/spool/squid" ]
#ENTRYPOINT [ "/usr/sbin/squid" ]
ENTRYPOINT [ "/bin/bash" ]
#CMD [ "-N" ]
