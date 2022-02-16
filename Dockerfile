# Build MVSCE
# If this is a point release use docker --build-arg RELEASE_VERSION=V#R#M#
FROM mainframed767/hercules:4.4.1.10647-SDL as sysgen
RUN apt-get update && apt-get -yq install --no-install-recommends git python3 python3-pip && apt-get clean
RUN git clone https://github.com/MVS-sysgen/sysgen.git
RUN pip3 install colorama
ARG RELEASE_VERSION=''
WORKDIR /sysgen
#ADD ./MVSCE.release.*.tar /sysgen
# sometimes sysgen fails ar random points, run until it build successfully
RUN until ./sysgen.py --timeout 500 --version ${RELEASE_VERSION}; do echo "Failed, rerunning"; done

## Now build the 
FROM mainframed767/hercules:4.4.1.10647-SDL
COPY --from=sysgen /sysgen/MVSCE /home/docker/MVSCE
COPY mvs.sh /home/docker
RUN apt-get update && apt-get -yq install --no-install-recommends socat && apt-get clean && \
    useradd -rm -s /bin/bash -u 1001 docker && \
    chmod +x -R /home/docker/mvs.sh && chown -R docker:docker /home/docker && \
    mkdir /config /dasd /printers /punchcards /logs /certs && \
    chown -R docker:docker /config /dasd /printers /punchcards /logs /certs
WORKDIR /home/docker
USER docker
VOLUME ["/config","/dasd","/printers","/punchcards","/logs", "/certs"]
EXPOSE 3221 3223 3270 3505 3506 8888
ENTRYPOINT ["./mvs.sh"]