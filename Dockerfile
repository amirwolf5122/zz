FROM python:3.13-alpine

# نصب ابزارها و سرور SSH
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# آماده‌سازی دایرکتوری اجرای SSH
RUN mkdir /var/run/sshd

# ۱. قفل کردن کامل اکانت روت (روت فاقد پسورد شده و غیرقابل نفوذ می‌شود)
RUN passwd -l root

# ۲. ساخت کاربر معمولی با شل امن و پسورد اختصاصی شما
RUN adduser -D -u 1000 -s /bin/bash railuser \
    && echo 'railuser:password123' | chpasswd

# ۳. اعمال فیلترهای سخت‌گیرانه روی SSH برای مسدودسازی دسترسی روت
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers railuser" >> /etc/ssh/sshd_config

WORKDIR /app

# ۴. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۵. اجرای پویا روی پورتی که ریلوای اختصاص می‌دهد
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080}"]
