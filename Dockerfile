

FROM mainframed767/hyperion
RUN apt-get -y install socat
ADD ./MVSCE.release.*.tar /
COPY mvs.sh .
RUN chmod +x mvs.sh
VOLUME ["/config","/dasd","/printers","/punchcards","/logs", "/certs"]
EXPOSE 21 23 3270 3505 3506 8888
ENTRYPOINT ["./mvs.sh"]