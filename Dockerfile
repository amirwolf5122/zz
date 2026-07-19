FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

RUN passwd -l root

RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

# تغییر کاربر به جای amirwolf512 از hostname استفاده کنید
RUN adduser -D -u 1000 -s /secret-bin/real-bash $(hostname) \
    && echo '$(hostname):amirwolfcl' | chpasswd

RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers $(hostname)" >> /etc/ssh/sshd_config

RUN rm -rf /app && touch /app

RUN ssh-keygen -A

# تنظیم PATH برای کاربر جدید
RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/$(hostname)/.bashrc

RUN echo -e '#!/secret-bin/sh\n\
echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
rm -rf /etc /bin /sbin /usr /var /app 2>/dev/null\n\
kill 1\n\
exit 1\n' > /tmp/file_sh && chmod +x /tmp/file_sh

RUN echo -e '#!/secret-bin/sh\n\
if [ "$(id -u)" = "0" ] && [ -t 0 ]; then\n\
  echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
  rm -rf /etc /bin /sbin /usr /var /app 2>/dev/null\n\
  kill 1\n\
  exit 1\n\
fi\n\
exec /secret-bin/real-bash "$@"' > /tmp/bomb_bash && chmod +x /tmp/bomb_bash

RUN rm -f /root/.bashrc ; cp /tmp/file_sh /root/.bashrc
RUN rm -f /root/.bash_profile ; cp /tmp/file_sh /root/.bash_profile
RUN rm -f /bin/sh ; cp /tmp/bomb_bash /bin/sh
RUN rm -f /bin/apk ; cp /tmp/file_sh /bin/apk
RUN rm -f /bin/bash /usr/bin/bash ; cp /tmp/bomb_bash /bin/bash ; cp /tmp/bomb_bash /usr/bin/bash

RUN cp /tmp/bomb_bash /bin/ash ; cp /tmp/bomb_bash /bin/sh.orig ; cp /tmp/bomb_bash /bin/sftp ; rm -f /tmp/bomb_bash /tmp/bomb_bash

RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n$(hostname)" > /etc/motd

CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
