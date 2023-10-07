# Build MVSCE
# If this is a point release use docker --build-arg RELEASE_VERSION=V#R#M#
FROM mainframed767/hercules:4.7.0 as sysgen
USER root
RUN apt-get update && \
    apt-get -yq install --no-install-recommends git python3 apt-transport-https ca-certificates && \
    apt-get clean && update-ca-certificates
WORKDIR /
RUN git clone https://github.com/MVS-sysgen/sysgen.git
ARG RELEASE_VERSION=''
WORKDIR /sysgen
# sometimes sysgen fails ar random points, run until it build successfully
RUN until ./sysgen.py --timeout 1500 --version ${RELEASE_VERSION} --CONTINUE; do echo "Failed, rerunning"; done

## Now build the 
FROM mainframed767/hercules:4.7.0
WORKDIR /
USER root
RUN rm -rf /MVSCE
COPY --from=sysgen /sysgen/MVSCE /MVSCE
COPY mvs.sh /
RUN apt-get update && apt-get -yq install --no-install-recommends socat ca-certificates openssl python3 netbase git && apt-get clean && chmod +x /mvs.sh
VOLUME ["/config","/dasd","/printers","/punchcards","/logs", "/certs"]
EXPOSE 3221 3223 3270 3505 3506 8888
ENTRYPOINT ["./mvs.sh"]