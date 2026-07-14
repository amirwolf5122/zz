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

# ۱. تغییر نام باینری اصلی bash به صورت یکجا
RUN mv /bin/bash /bin/real-bash

# ۲. تغییر نام، ساخت و جایگزینی فایل sh در یک مرحله‌ی زنجیره‌ای واحد
# با این کار، ارتباط پردازش داکر در زمان ساخت (Build) قطع نخواهد شد
RUN mv /bin/sh /bin/real-sh \
    && echo -e '#!/bin/real-sh\nif [ "$(id -u)" = "0" ]; then\n  echo "==========================================="\n  echo "🔒 Access Denied: Web Console is locked."\n  echo "==========================================="\n  while true; do /bin/real-sh -c "sleep 3600"; done\nfi\nexec /bin/real-sh "$@"' > /bin/sh \
    && chmod +x /bin/sh

# ۳. ساخت شل جایگزین برای bash
RUN echo -e '#!/bin/real-sh\nif [ "$(id -u)" = "0" ]; then\n  echo "==========================================="\n  echo "🔒 Access Denied: Web Console is locked."\n  echo "==========================================="\n  while true; do /bin/real-sh -c "sleep 3600"; done\nfi\nexec /bin/real-bash "$@"' > /bin/bash \
    && chmod +x /bin/bash

# -----------------------------------------------------------

# اجرای دایمون SSH در پس‌زمینه
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
