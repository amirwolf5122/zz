FROM python:3.13-alpine

# نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ساخت پوشه ران‌تایم SSH با دسترسی امن و مناسب
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# قفل کردن اکانت روت
RUN passwd -l root

# ساخت کاربر غیر روت
RUN adduser -D -u 1000 -s /bin/bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# تنظیمات امنیت SSH (غیرفعال کردن روت، فعال‌سازی پسورد و محدود کردن کاربر)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

# تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۱. قطع اتصال ورودی استاندارد (stdin) با استفاده از < /dev/null
# ۲. هدایت خروجی‌ها به جاده ابریشم جهت عدم نمایش در وب‌کنسول با > /dev/null 2>&1
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D -o Port=${PORT:-8080} < /dev/null > /dev/null 2>&1"]
