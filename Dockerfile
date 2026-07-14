FROM python:3.13-alpine

# نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# قفل کردن پسورد اکانت روت
RUN passwd -l root

# ساخت کاربر غیر روت برای استفاده در SSH/SFTP
RUN adduser -D -u 1000 -s /bin/bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# تنظیمات امنیت SSH
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

# تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# --- [دیوار دفاعی شل: مسدودسازی ۱۰۰٪ دسترسی روت در وب‌کنسول] ---

# ۱. انتقال باینری واقعی bash به یک مسیر دیگر برای دور زدن روت
RUN mv /bin/bash /bin/real-bash

# ۲. ایجاد اسکریپت مسدودکننده شل بدون دستکاری مستقیم نام busybox
# این اسکریپت جایگزین bash و sh اصلی می‌شود و روت را قفل می‌کند
RUN echo -e '#!/bin/busybox sh\n\
if [ "$(id -u)" = "0" ]; then\n\
  echo "==========================================="\n\
  echo "🔒 Access Denied: Web Console is locked."\n\
  echo "==========================================="\n\
  while true; do /bin/busybox sleep 3600; done\n\
fi\n\
exec /bin/busybox sh "$@"' > /bin/temp-sh && chmod +x /bin/temp-sh

# حالا باینری‌های فعال سیستم را با اسکریپت بالا جایگزین می‌کنیم
RUN mv /bin/temp-sh /bin/sh

RUN echo -e '#!/bin/busybox sh\n\
if [ "$(id -u)" = "0" ]; then\n\
  echo "==========================================="\n\
  echo "🔒 Access Denied: Web Console is locked."\n\
  echo "==========================================="\n\
  while true; do /bin/busybox sleep 3600; done\n\
fi\n\
exec /bin/real-bash "$@"' > /bin/bash && chmod +x /bin/bash

# -----------------------------------------------------------

# اجرای دایمون SSH در پس‌زمینه
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
