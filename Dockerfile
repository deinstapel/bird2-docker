# BIRD routing daemon, see http://bird.network.cz

FROM debian:buster-slim

RUN set -e -x \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y upgrade \
#
# download, compile and install bird v2
#
    && apt-get -y --no-install-recommends install libreadline7 \
    && dpkg-query -f '${binary:Package}\n' -W | sort > /tmp/base_packages \
    && apt-get -y --no-install-recommends install \
        curl gcc libc6-dev make bison flex libncurses-dev libreadline-dev \
    && latest=$(curl -s -S ftp://bird.network.cz/pub/bird/ | sed -n 's/^.*LATEST-IS-\(2.*\)/\1/p') \
    && if [ -z "$latest" ]; then echo "Latest BIRD package not found" >&2; exit 1; fi \
    && curl -s -S "ftp://bird.network.cz/pub/bird/bird-$latest.tar.gz" | tar xz \
    && cd bird* \
    && ./configure --sysconfdir='/etc/bird'\
    && make \
    && strip -s bird birdc birdcl \
    && make install \
    && cd .. \
    && rm -rf bird* \
    && dpkg-query -f '${binary:Package}\n' -W | sort > /tmp/packages \
    && comm -13 /tmp/base_packages /tmp/packages | xargs apt-get -y purge \
    && rm -f /tmp/base_packages /tmp/packages \
#
# install remaining tools
#
    && apt-get -y --no-install-recommends install \
        net-tools iproute2 ifupdown inetutils-ping \
        telnet traceroute procps nano mtr \
    && rm -rf /var/lib/apt/lists/* \
#
# setup BIRD
#
    && printf '\
\043!/bin/sh\n\
\n\
bird\n\
cd /etc/bird\n\
exec bash -i -l\n' \
        > /etc/init.sh && chmod +x /etc/init.sh

VOLUME [ "/etc/bird" ]
CMD [ "/etc/init.sh" ]
