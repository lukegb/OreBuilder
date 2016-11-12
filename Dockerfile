FROM openjdk:8u102-jdk

MAINTAINER Luke Granger-Brown <docker@lukegb.com>

LABEL io.openshift.tags="builder,sbt"
ENV SBT_VERSION=0.13 \
    SBT_FULL_VERSION=0.13.11

# Install sbt
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    echo "deb http://dl.bintray.com/sbt/debian /" > /etc/apt/sources.list.d/sbt.list && \
    apt-get update && apt-get install -y sbt && rm -rf /var/lib/apt/lists/*

# Defines the S2I scripts location
LABEL io.openshift.s2i.scripts-url=image:///usr/local/s2i
# Copy the S2I scripts in
COPY ./.s2i/bin/ /usr/local/s2i

# Create app user
RUN mkdir /opt/app-root && mkdir /opt/app && \
    useradd -u 1001 -r -g 0 -d /opt/app-root -s /sbin/nologin \
      -c "Default Application User" default && \
    chown -R 1001:0 /opt/app-root && chown -R 1001:0 /opt/app
ENV HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
    SBT_OPTS="-Dsbt.override.build.repos=true"
WORKDIR /opt/app-root
USER 1001

# Set up authenticated repository
ENV SBT_CREDENTIALS /opt/app-root/.sbt/.credentials
RUN mkdir /opt/app-root/.sbt && \
    printf '[repositories]\nlocal\nivy-proxy-releases: https://%s/repository/proxy-ivy/, [organization]/[module]/(scala_[scalaVersion]/)(sbt_[sbtVersion]/)[revision]/[type]s/[artifact](-[classifier]).[ext]\nmaven-proxy-releases: https://%s/repository/proxy-maven/\n' ${AUTH_HOST} ${AUTH_HOST} > /opt/app-root/.sbt/repositories && \
    mkdir -p /opt/app-root/.sbt/${SBT_VERSION}/plugins && \
    printf 'credentials += Credentials(new File("%s"))\n' "${SBT_CREDENTIALS}" > /opt/app-root/.sbt/0.13/plugins/credentials.sbt && \
    printf 'realm=%s\nhost=%s\nuser=%s\npassword=%s\n' "${AUTH_REALM}" "${AUTH_HOST}" "${AUTH_USER}" "${AUTH_PASSWORD}" > "${SBT_CREDENTIALS}"

# Run sbt to precache it
RUN sbt -sbt-version ${SBT_FULL_VERSION} about
