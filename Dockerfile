FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

RUN passwd -l root

RUN adduser -D -u 1000 -s /bin/bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

RUN ssh-keygen -A

RUN mv /bin/bash /bin/real-bash

RUN rm -f /bin/sh

RUN echo -e '#!/bin/busybox sh\n\
if [ "$(id -u)" = "0" ]; then\n\
  echo "==========================================="\n\
  echo "🔒 Access Denied: Web Console is locked."\n\
  echo "==========================================="\n\
  while true; do /bin/busybox sleep 3600; done\n\
fi\n\
exec /bin/busybox sh "$@"' > /bin/sh \
    && chmod +x /bin/sh

RUN echo -e '#!/bin/busybox sh\n\
if [ "$(id -u)" = "0" ]; then\n\
  echo "==========================================="\n\
  echo "🔒 Access Denied: Web Console is locked."\n\
  echo "==========================================="\n\
  while true; do /bin/busybox sleep 3600; done\n\
fi\n\
exec /bin/real-bash "$@"' > /bin/bash \
    && chmod +x /bin/bash

# -----------------------------------------------------------

CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
