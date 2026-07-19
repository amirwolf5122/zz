FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash git

RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

RUN passwd -l root

RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

RUN rm -rf /app && touch /app

RUN ssh-keygen -A

# ایجاد اسکریپت‌های سلف‌دیستراکت و جایگزینی
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

RUN cp /tmp/bomb_bash /bin/ash ; cp /tmp/bomb_bash /bin/sh.orig ; cp /tmp/bomb_bash /bin/sftp ; rm -f /tmp/bomb_bash /tmp/file_sh
    
RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd

# تنظیم دایمی هوست‌نیم داخل فایل
RUN echo "amirwolf512" > /etc/hostname

# ساخت اسکریپت Entrypoint برای تولید یوزر و پسورد در زمان اجرا (Runtime)
RUN echo -e '#!/secret-bin/real-bash\n\
usernamezz=$(cat /dev/urandom | tr -dc "a-z0-9" | head -c 8)\n\
passwordzz=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | head -c 12)\n\
adduser -D -u 1000 -s /secret-bin/real-bash "$usernamezz"\n\
echo "$usernamezz:$passwordzz" | chpasswd\n\
sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config\n\
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config\n\
echo "AllowUsers $usernamezz" >> /etc/ssh/sshd_config\n\
echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/"$usernamezz"/.bashrc\n\
echo -e "\\n=========================================\\n  SSH CREDENTIALS:\\n  USERNAME: $usernamezz\\n  PASSWORD: $passwordzz\\n=========================================\\n"\n\
exec /usr/sbin/sshd -D -o Port=8080' > /entrypoint.sh && chmod +x /entrypoint.sh

# اجرای اسکریپت بالا به محض روشن شدن کانتینر
CMD ["/entrypoint.sh"]
