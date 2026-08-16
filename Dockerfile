FROM python:3.13-alpine
RUN apk add --no-cache bash gcompat dropbear openssh-sftp-server inotify-tools \
    && mkdir -p /secret-bin /etc/dropbear \
    && passwd -l root \
	&& sed -i 's|^root:.*|root:x:0:0:root:/root:/bin/false|' /etc/passwd \
    \
    && cp /bin/busybox /secret-bin/ \
    && chown root:root /secret-bin/busybox \
    && chmod 700 /secret-bin/busybox \
    && mv /bin/bash /secret-bin/real-bash \
    && ln -s /secret-bin/real-bash /secret-bin/sh \
    && ln -s /secret-bin/real-bash /secret-bin/ash \
    && for cmd in ls cat mkdir rm cp mv echo chmod grep sed awk find clear dirnames base64 unzip; do \
         ln -s /secret-bin/busybox /secret-bin/$cmd 2>/dev/null || true; \
         done \
    \
    && echo "/secret-bin/real-bash" >> /etc/shells \
    && rm -rf /app && echo "bye" > /app \
    \
    && dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key \
    && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key \
    && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key \
    \
    && echo -e '#!/secret-bin/sh\necho "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\necho "bye" > /.open\nsleep 2\nrm -rf /home\nkill 1\nexit 1\n' > /tmp/file_sh \
    && chmod +x /tmp/file_sh \
    && echo -e '#!/secret-bin/sh\nif [ "$(id -u)" = "0" ] && [ -t 0 ]; then\n  echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\necho "bye" > /.open\nsleep 2\n  kill 1\n  exit 1\nfi\nexec /secret-bin/real-bash "$@"' > /tmp/bomb_bash \
    && chmod +x /tmp/bomb_bash \
    \
    && for bin in ps apk top htop lsof pgrep; do \
      paths=$(which -a $bin 2>/dev/null || find /bin /sbin /usr/bin /usr/sbin -name $bin 2>/dev/null); \
      for p in $paths; do \
        if [ -e "$p" ]; then \
          rm -f "$p"; \
          echo -e "#!/secret-bin/sh\nif [ \"\$(id -u)\" != \"0\" ]; then echo \"Permission denied\"; exit 1; fi\nexec /secret-bin/busybox $bin \"\$@\"" > "$p"; \
          chmod 700 "$p"; \
          chown root:root "$p"; \
        fi; \
      done; \
    done \
    \
    && rm -f /root/.bashrc /root/.bash_profile \
    && cp /tmp/file_sh /root/.bashrc \
    && cp /tmp/file_sh /root/.bash_profile \
    \
    && rm -rf /usr/local/lib/python3.13/test \
    && find /usr/local/lib/python3.13/ -name '__pycache__' -exec rm -r {} + \
    \
    && echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd \
    && echo -e '#!/secret-bin/real-bash\n\
usernamezz="a$(cat /dev/urandom | tr -dc "0-9" | head -c 7)"\n\
passwordzz="A$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | head -c 10)"\n\
adduser -D -u 1000 -s /secret-bin/real-bash "$usernamezz" 2>/dev/null\n\
echo "$usernamezz:$passwordzz" | chpasswd\n\
echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/"$usernamezz"/.bashrc\n\
echo "export PS1=\"[amirwolf512]:\\\\w\\\\$ \"" >> /home/"$usernamezz"/.bashrc\n\
echo -e "========================================="\n\
echo -e "  USERNAME: $usernamezz"\n\
echo -e "  PASSWORD: $passwordzz"\n\
echo -e "========================================="\n\
\n\
detonate() {\n\
  echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
  echo "bye" > /.open\n\
  sleep 2\n\
  rm -rf /home\n\
  kill 1\n\
  exit 1\n\
}\n\
\ninotifywait -m -r -e modify,create,delete,moved_to,moved_from /etc /bin /sbin /usr /secret-bin /var /root /app 2>/dev/null | while read path action file; do\n\
  detonate\n\
done &\n\
INOTIFY_PID=$!\n\
exec /usr/sbin/dropbear -F -p 8080 >/dev/null 2>&1 &\n\
DROPBEAR_PID=$!\n\
while true; do\n\
  if [ -s /tmp/killssh ]; then\n\
    rm -f /tmp/killssh\n\
    killall -9 dropbear 2>/dev/null\n\
    killall -9 sftp-server 2>/dev/null\n\
  fi\n\
  if [ -e /.open ]; then\n\
    kill "$DROPBEAR_PID" 2>/dev/null\n\
    break\n\
  fi\n\
  if ! kill -0 $INOTIFY_PID 2>/dev/null; then\n\
    detonate\n\
  fi\n\
  sleep 2\n\
done\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh \
    \
    && rm -f /bin/sh /bin/bash /usr/bin/bash \
    && cp /tmp/bomb_bash /bin/sh \
    && cp /tmp/bomb_bash /bin/bash \
    && cp /tmp/bomb_bash /usr/bin/bash \
    && cp /tmp/bomb_bash /bin/ash \
    && cp /tmp/bomb_bash /bin/sh.orig \
    && cp /tmp/bomb_bash /bin/sftp \
    && rm -f /tmp/bomb_bash /tmp/file_sh

CMD ["/entrypoint.sh"]
