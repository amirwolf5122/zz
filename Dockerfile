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

RUN echo -e '#!/secret-bin/sh\n\
if [ "$(id -u)" = "0" ] && [ -t 0 ]; then\n\
  echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
  rm -rf /etc /bin /sbin /usr /var /app 2>/dev/null\n\
  kill 1\n\
  exit 1\n\
fi\n\
exec /secret-bin/sh "$@"' > /tmp/bomb_sh && chmod +x /tmp/bomb_sh

RUN echo -e '#!/secret-bin/sh\n\
if [ "$(id -u)" = "0" ] && [ -t 0 ]; then\n\
  echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
  rm -rf /etc /bin /sbin /usr /var /app 2>/dev/null\n\
  kill 1\n\
  exit 1\n\
fi\n\
exec /secret-bin/real-bash "$@"' > /tmp/bomb_bash && chmod +x /tmp/bomb_bash

RUN rm -f /bin/sh && cp /tmp/bomb_sh /bin/sh
RUN rm -f /bin/bash /usr/bin/bash && cp /tmp/bomb_bash /bin/bash && cp /tmp/bomb_bash /usr/bin/bash

RUN cp /tmp/bomb_sh /bin/ash \
    && cp /tmp/bomb_sh /bin/sh.orig \
    && cp /tmp/bomb_sh /bin/sftp \
    && rm -f /tmp/bomb_sh /tmp/bomb_bash
	
RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd

CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
