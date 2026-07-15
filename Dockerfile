FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

RUN passwd -l root

RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

RUN adduser -D -u 1000 -s /secret-bin/real-bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config


RUN rm -rf /app && touch /app

RUN ssh-keygen -A

RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc


RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd

CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
