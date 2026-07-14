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

RUN sed -i 's|root:x:0:0:root:/root:/bin/sh|root:x:0:0:root:/root:/sbin/nologin|g' /etc/passwd

RUN echo -e '#!/bin/sh\necho "Access Denied: Root access is strictly disabled."\nexit 1' > /bin/disabled-shell \
    && chmod +x /bin/disabled-shell
# -----------------------------------------------

CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
