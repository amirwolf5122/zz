FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ۲. ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# ۳. قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ۴. انتقال تمام شل‌های سیستم به یک مسیر مخفی که فقط SSH از آن خبر دارد
# با این کار، هیچ شلی در مسیرهای استاندارد (/bin/sh یا /bin/bash) برای ریلوای باقی نمی‌ماند
RUN mkdir -p /secret-bin \
    && cp /bin/busybox /secret-bin/ \
    && ln -s ./busybox /secret-bin/sh \
    && ln -s ./busybox /secret-bin/ash \
    && mv /bin/bash /secret-bin/real-bash

# ۵. ساخت کاربر غیر روت و متصل کردن مستقیم شل آن به مسیر مخفی
RUN adduser -D -u 1000 -s /secret-bin/real-bash amirwolf512 \
    && echo 'amirwolf512:amirwolfcl' | chpasswd

# ۶. تنظیمات امنیت SSH (اجازه ورود فقط به amirwolf512)
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "AllowUsers amirwolf512" >> /etc/ssh/sshd_config

WORKDIR /app

# ۷. تولید کلیدهای هاست SSH
RUN ssh-keygen -A

# ۸. نابود کردن فیزیکی تمام شل‌های عمومی سیستم!
# حالا سیستم‌عامل در مسیرهای پیش‌فرض هیچ شلی برای باز کردن وب‌کنسول ندارد
RUN rm -f /bin/sh /bin/ash /bin/bash /usr/bin/bash /bin/sh.orig

# ۹. ست کردن مسیر اختصاصی امن برای کاربر شما در زمان اتصال به SSH
RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc

# اجرای مستقیم دایمون SSH با مسیر مطلق (بدون نیاز به شل سیستم)
CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
