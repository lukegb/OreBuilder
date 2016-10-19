FROM openjdk:8u102-jdk

MAINTAINER Luke Granger-Brown <docker@lukegb.com>

LABEL io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,sbt"

# Install sbt
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    echo "deb http://dl.bintray.com/sbt/debian /" > /etc/apt/sources.list.d/sbt.list && \
    apt-get update && apt-get install -y sbt && rm -rf /var/lib/apt/lists/*

# Defines the S2I scripts location
LABEL io.openshift.s2i.scripts-url=image:///usr/local/s2i
# Copy the S2I scripts in
COPY ./.s2i/bin/ /usr/local/s2i

# Specify the ports for the final image
EXPOSE 8080
