FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز (شل‌ها کاملاً سالم می‌مانند)
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

# --- [دیوار دفاعی جدید: اخراج فوری روت در وب‌کنسول] ---
# نوشتن دستور exit در تمام فایل‌های لودینگ روت تا به محض ورود تعاملی، بیرون انداخته شود.
# این فایل‌ها در زمان بیلد (Build) غیرفعال هستند، پس هیچ مشکلی برای ساخت داکر ایجاد نمی‌کنند.
#RUN echo "exit 1" >> /root/.bashrc \
#    && echo "exit 1" >> /root/.bash_profile \
#    && echo "exit 1" >> /root/.profile

# برای اطمینان بیشتر، اگر ریلوای فایل‌های روت را دور زد، در پروفایل اصلی سیستم هم می‌گوییم اگر روت بود اخراج شود:
#RUN echo 'if [ "$(id -u)" = "0" ]; then exit 1; fi' >> /etc/profile
# -----------------------------------------------------------

# اجرای مستقیم دایمون SSH
#RUN rm -rf /bin/sftp /bin/bash /bin/sh
CMD sleep 9999
#CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
