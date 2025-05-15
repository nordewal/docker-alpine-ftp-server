ARG BASE_IMG=alpine:3.19

FROM $BASE_IMG

RUN apk --no-cache add vsftpd openssl

COPY start_vsftpd.sh /bin/start_vsftpd.sh
COPY vsftpd.conf /etc/vsftpd/vsftpd.conf

EXPOSE 21 21000-21010

ENTRYPOINT ["/bin/start_vsftpd.sh"]
