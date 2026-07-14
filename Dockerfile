FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ۲. ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# ۳. قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ۴. ساخت کاربر غیر روت برای استفاده در SSH/SFTP
RUN adduser -D -u 1000 -s /bin/bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# ۵. تنظیمات امنیت SSH (اجازه ورود فقط به amirwolf512)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

# ۶. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# --- [دیوار دفاعی نهایی: خلع سلاح وب‌کنسول ریلوای] ---

# ایجاد یک مسیر امن برای کاربر amirwolf512 تا ابزارهای مورد نیازش را حفظ کند
RUN mkdir -p /home/amirwolf512/bin \
    && cp /bin/busybox /home/amirwolf512/bin/ \
    && ln -s ./busybox /home/amirwolf512/bin/id \
    && ln -s ./busybox /home/amirwolf512/bin/sleep \
    && chown -R amirwolf512:amirwolf512 /home/amirwolf512/bin

# حذف کامل و فیزیکی دستورات id و sleep از مسیرهای عمومی سیستم (که ریلوای از آن‌ها استفاده می‌کند)
RUN rm -f /usr/bin/id /bin/id /bin/sleep /usr/bin/sleep

# ست کردن مسیر اختصاصی امن برای کاربر شما در زمان اتصال به SSH (با کلمه کلیدی RUN)
RUN echo "export PATH=/home/amirwolf512/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc
# -----------------------------------------------------------

ENV SHELL=/sbin/nologin

# اجرای مستقیم دایمون SSH به عنوان تنها فرآیند کانتینر
CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
