FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash


RUN mkdir /var/run/sshd

RUN passwd -l root

RUN adduser -D -u 1000 -s /bin/bash railuser \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers railuser" >> /etc/ssh/sshd_config

WORKDIR /app

# ۴. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۵. اجرای پویا روی پورتی که ریلوای اختصاص می‌دهد
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
