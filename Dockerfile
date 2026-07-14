FROM python:3.13-alpine

# نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ساخت کاربر غیر روت برای استفاده در SSH/SFTP
RUN adduser -D -u 1000 -s /bin/bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# تنظیمات امنیت SSH (اجازه ورود فقط به amirwolf512)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

# تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# --- [دیوار دفاعی جدید: نابود کردن متغیرهای شل سیستم] ---

# تغییر شل پیش‌فرض روت در سیستم به یک مسیر کاملاً نامعتبر
RUN sed -i 's|root:x:0:0:root:/root:/bin/sh|root:x:0:0:root:/root:/sbin/nologin|g' /etc/passwd

# تعریف متغیرهای محیطی به طوری که هر ابزار اتصالی (مثل ریلوای) کاملاً گمراه شود
ENV SHELL=/sbin/nologin
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=dumb

# -----------------------------------------------------------

# اجرای مستقیم دایمون SSH با مسیر مطلق (بدون وابستگی به شل‌های پیش‌فرض)
CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
