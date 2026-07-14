FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ۲. ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# ۳. قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ۴. ساخت پوشه امن و انتقال شل واقعی به مسیر مخفی
RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

# ۵. ساخت کاربر غیر روت متصل به شل مخفی
RUN adduser -D -u 1000 -s /secret-bin/real-bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# ۶. تنظیمات امنیت SSH (فقط اجازه ورود به amirwolf512)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

# --- [تبدیل پوشه app به فایل] ---
# ابتدا اگر پوشه app وجود دارد آن را به صورت بازگشتی حذف می‌کنیم، 
# سپس یک فایل خالی به نام app در مسیر اصلی ایجاد می‌کنیم.
WORKDIR /app
# --------------------------------

# ۷. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۸. ست کردن مسیر PATH برای کاربر شما
RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc

# ۹. ساخت اسکریپت پس‌زمینه پاک‌سازی ثانیه‌ای شل‌ها
RUN echo -e '#!/secret-bin/sh\n\
#rm -rf /app && touch /app\n\
while true; do\n\
  #echo "kill 1" > /bin/sh ; echo "kill 1" > /bin/ash ; /bin/bash ; echo "kill 1" > /usr/bin/bash ; echo "kill 1" > /bin/sh.orig ; echo "kill 1" > /bin/sftp\n\
  sleep 1\n\
done' > /secret-bin/cleaner.sh && chmod +x /secret-bin/cleaner.sh

# اجرای همزمان اسکریپت پاک‌سازی در پس‌زمینه و سرویس SSH
CMD /secret-bin/cleaner.sh & exec /usr/sbin/sshd -D -o Port=8080
