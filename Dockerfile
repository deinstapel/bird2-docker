FROM debian:buster AS compiler
EXPOSE 179

# This Dockerfile is inspired from https://hub.docker.com/r/pierky/bird
# These are multi-stage build to reduce disk usage thanks to @jptazzo https://intro-2019-04.container.training/#196
# You may also want to try alpine instead of debian -Left as an exercise for the reader-

# This image is build with the command : `docker build -t afenioux/bird --build-arg BIRDV=2.0.6 .`

# The host's file at /somewhere/bird/bird.conf is used as the configuration file for BIRD (/etc/bird/bird.conf in the containter)
# if you run with this option : `docker run -d -p 179:179 -v /mnt/flash/docker/bird:/etc/bird:rw --memory 512m --memory-swap 512m --cpus 1.1 afenioux/bird`
# logs are available with `docker logs <container_id>` if you set `log stderr all;` in bird.conf, but you may write in a file like /etc/bird/bird.logs

RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    build-essential \
    curl \
    flex \
    libreadline-dev \
    libncurses5-dev \
    m4 \
    unzip

WORKDIR /tmp
ARG BIRDV=2.0.12
RUN curl -O -L ftp://bird.network.cz/pub/bird/bird-${BIRDV}.tar.gz
RUN tar -xvzf bird-${BIRDV}.tar.gz

WORKDIR /tmp/bird-${BIRDV}
RUN ./configure --prefix=/usr --sysconfdir=/etc/bird --localstatedir=/var --with-runtimedir=/run/bird && \
    make

FROM debian:buster
RUN apt-get update && apt-get install -y libreadline7 libncurses5 libc6
ARG BIRDV=2.0.12
COPY --from=compiler /tmp/bird-${BIRDV}/bird /tmp/bird-${BIRDV}/birdc /tmp/bird-${BIRDV}/birdcl /usr/local/sbin/
RUN mkdir /etc/bird /run/bird
# Set Timezone to Europe
ENV TZ=Europe/Paris
RUN echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Add some stuff for debugging network
#RUN apt-get install -y tcpdump netcat

CMD bird -d