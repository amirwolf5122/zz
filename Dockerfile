FROM python:3.13-alpine

RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash git build-base binutils

RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

RUN passwd -l root && usermod -s /bin/false root 2>/dev/null || true

RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && cp /bin/bash /secret-bin/user-bash

RUN usernamezz="a$(cat /dev/urandom | tr -dc '0-9' | head -c 7)" \
    && passwordzz="A$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)" \
    && adduser -D -u 1000 -s /secret-bin/user-bash "$usernamezz" \
    && echo "$usernamezz:$passwordzz" | chpasswd \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers $usernamezz" >> /etc/ssh/sshd_config \
    && echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/"$usernamezz"/.bashrc \
    && echo "export PS1='[amirwolf512]:\w\$ '" >> /home/"$usernamezz"/.bashrc \
    && echo -e "USERNAME: $usernamezz\nPASSWORD: $passwordzz" > /etc/.ssh_creds

RUN rm -rf /app && touch /app
RUN ssh-keygen -A

RUN for bin in ps apk top htop lsof pgrep; do \
      paths=$(which -a $bin 2>/dev/null || find /bin /sbin /usr/bin /usr/sbin -name $bin 2>/dev/null); \
      for p in $paths; do \
        if [ -e "$p" ]; then \
          rm -f "$p"; \
          echo -e "#!/secret-bin/sh\necho \"Permission denied\"\nexit 1" > "$p"; \
          chmod 755 "$p"; \
        fi; \
      done; \
    done

RUN echo -e '#!/secret-bin/sh\necho "Access Denied: Terminal/CLI execution is disabled."\nexit 1' > /tmp/block_exec \
    && chmod +x /tmp/block_exec \
    && cp /tmp/block_exec /bin/sh \
    && cp /tmp/block_exec /bin/bash \
    && cp /tmp/block_exec /usr/bin/bash \
    && cp /tmp/block_exec /bin/ash \
    && rm -f /tmp/block_exec

RUN rm -f /root/.bashrc /root/.bash_profile

RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd

RUN echo -e '#!/secret-bin/sh\n\
if [ -f /etc/.ssh_creds ]; then\n\
  echo -e "\\n=========================================\\n  SSH CREDENTIALS (BUILD TIME):"\n\
  cat /etc/.ssh_creds\n\
  echo -e "=========================================\\n"\n\
fi\n\
exec /usr/sbin/sshd -D -o Port=8080' > /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
