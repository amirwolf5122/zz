FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ۲. ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# ۳. قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ۴. انتقال شل‌های واقعی به پوشه امن و مخفی
RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

# ۵. ساخت کاربر غیر روت amirwolf512
RUN adduser -D -u 1000 -s /secret-bin/real-bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# ۶. تنظیمات امنیت SSH (فقط اجازه ورود به amirwolf512)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

# --- [تبدیل پوشه app به فایل] ---
#RUN rm -rf /app && touch /app
# --------------------------------

# ۷. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۸. ست کردن مسیر PATH برای کاربر شما
RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc
RUN echo -e "Telegram:@amir_wolf512 HI:3\n\n==========>\n" > /etc/motd

# اجرای مستقیم سرویس SSH
CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
