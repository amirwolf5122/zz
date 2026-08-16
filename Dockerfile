FROM python:3.13-alpine

RUN apk add --no-cache bash gcompat dropbear openssh-sftp-server inotify-tools \
    && mkdir -p /secret-bin /etc/dropbear /var/run \
    && passwd -l root \
    && sed -i 's|^root:.*|root:x:0:0:root:/root:/bin/false|' /etc/passwd \
    \
    && cp /bin/busybox /secret-bin/ \
    && chown root:root /secret-bin/busybox \
    && chmod 700 /secret-bin/busybox \
    && mv /bin/bash /secret-bin/real-bash \
    && ln -s /secret-bin/real-bash /secret-bin/sh \
    && ln -s /secret-bin/real-bash /secret-bin/ash \
    && for cmd in ls cat mkdir rm cp mv echo chmod grep sed awk find clear dirname base64 unzip id whoami; do \
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
    && echo -e '#!/secret-bin/sh\n\
echo "CRITICAL SECURITY BREACH! SELF-DESTRUCTING..."\n\
echo "bye" > /.open\n\
sleep 1\n\
rm -rf /home /tmp /var/tmp 2>/dev/null\n\
kill -9 1 2>/dev/null\n\
exit 1\n' > /secret-bin/detonate \
    && chmod 700 /secret-bin/detonate \
    \
    && echo -e '#!/secret-bin/sh\n\
if [ "$(id -u)" = "0" ]; then\n\
  /secret-bin/detonate\n\
fi\n\
exec /secret-bin/real-bash "$@"\n' > /tmp/bomb_bash \
    && chmod +x /tmp/bomb_bash \
    \
    && for bin in ps apk top htop lsof pgrep su sudo; do \
      paths=$(which -a $bin 2>/dev/null || find /bin /sbin /usr/bin /usr/sbin -name $bin 2>/dev/null); \
      for p in $paths; do \
        if [ -e "$p" ]; then \
          rm -f "$p"; \
          echo -e "#!/secret-bin/sh\necho \"Permission denied\"; exit 1\n" > "$p"; \
          chmod 700 "$p"; \
        fi; \
      done; \
    done \
    \
    && rm -f /root/.bashrc /root/.bash_profile /root/.profile \
    && cp /secret-bin/detonate /root/.bashrc \
    && cp /secret-bin/detonate /root/.bash_profile \
    && cp /secret-bin/detonate /root/.profile \
    \
    && rm -rf /usr/local/lib/python3.13/test \
    && find /usr/local/lib/python3.13/ -name '__pycache__' -exec rm -r {} + 2>/dev/null || true \
    \
    && echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd \
    \
    && echo -e '#!/secret-bin/sh\ntouch .killssh\necho "SSH DISABLED"\n' > /secret-bin/killssh \
    && chmod 755 /secret-bin/killssh \
    \
    && echo -e '#!/secret-bin/real-bash\n\
set -e\n\
\n\
usernamezz="a$(cat /dev/urandom | tr -dc "0-9" | head -c 7)"\n\
passwordzz="A$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | head -c 10)"\n\
\n\
adduser -D -u 1000 -s /secret-bin/real-bash "$usernamezz" 2>/dev/null || true\n\
echo "$usernamezz:$passwordzz" | chpasswd\n\
\n\
chown -R "$usernamezz:$usernamezz" /home/"$usernamezz"\n\
chmod 700 /home/"$usernamezz"\n\
\n\
echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /home/"$usernamezz"/.bashrc\n\
echo "export PS1=\"[amirwolf512]:\\\\w\\\\$ \"" >> /home/"$usernamezz"/.bashrc\n\
chown "$usernamezz:$usernamezz" /home/"$usernamezz"/.bashrc\n\
\n\
echo "========================================="\n\
echo " SSH CREDENTIALS (NON-ROOT ONLY):"\n\
echo " USERNAME: $usernamezz"\n\
echo " PASSWORD: $passwordzz"\n\
echo " PORT    : 8080"\n\
echo "========================================="\n\
\n\
inotifywait -m -r -e modify,create,delete,moved_to,moved_from \\\n\
  /etc /bin /sbin /usr /secret-bin /var /root /app 2>/dev/null | while read path action file; do\n\
  case "$path$file" in\n\
    *dropbear*|*/home/*|/tmp/*) ;;\n\
    *) /secret-bin/detonate ;;\n\
  esac\n\
done &\n\
INOTIFY_PID=$!\n\
\n\
(\n\
  while true; do\n\
    if ! kill -0 $INOTIFY_PID 2>/dev/null; then\n\
      /secret-bin/detonate\n\
    fi\n\
    sleep 2\n\
  done\n\
) &\n\
\n\
/usr/sbin/dropbear -F -p 8080 -w -T 2 -j -k -b /etc/motd >/dev/null 2>&1 &\n\
DROPBEAR_PID=$!\n\
\n\
while true; do\n\
  if [ -f .killssh ]; then\n\
    kill -9 "$DROPBEAR_PID" 2>/dev/null || true\n\
    echo "SSH DISABLED"\n\
    while true; do sleep 3600; done\n\
  fi\n\
\n\
  if ! kill -0 "$DROPBEAR_PID" 2>/dev/null; then\n\
    if [ ! -f .killssh ]; then\n\
      /usr/sbin/dropbear -F -p 8080 -w -T 2 -j -k -b /etc/motd >/dev/null 2>&1 &\n\
      DROPBEAR_PID=$!\n\
    fi\n\
  fi\n\
  sleep 1\n\
done\n' > /entrypoint.sh \
    && chmod 700 /entrypoint.sh \
    \
    && rm -f /bin/sh /bin/bash /usr/bin/bash /bin/ash /bin/sftp \
    && cp /tmp/bomb_bash /bin/sh \
    && cp /tmp/bomb_bash /bin/bash \
    && cp /tmp/bomb_bash /usr/bin/bash \
    && cp /tmp/bomb_bash /bin/ash \
    && cp /tmp/bomb_bash /bin/sftp \
    && rm -f /tmp/bomb_bash \
    && chmod 700 /secret-bin/*

CMD ["/entrypoint.sh"]
