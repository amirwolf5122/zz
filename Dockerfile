FROM python:3.13-alpine

# ۱. نصب پکیج‌های مورد نیاز
RUN apk add --no-cache zip unzip ffmpeg whois openssh bash-completion bash

# ۲. ساخت پوشه ران‌تایم SSH
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# ۳. قفل کردن کامل پسورد اکانت روت
RUN passwd -l root

# ۴. انتقال تمام شل‌های سیستم به یک مسیر مخفی که فقط SSH از آن خبر دارد
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

# ۸. تنظیم مسیر اختصاصی کاربر شما (این خط را قبل از پاک کردن شل‌ها اجرا می‌کنیم)
RUN echo "export PATH=/secret-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /home/amirwolf512/.bashrc

# ۹. پاک‌سازی فیزیکی و نهایی شل‌های عمومی کانتینر (آخرین لایه اجرایی داکر)
# بعد از این لایه، داکر دیگر هیچ دستور RUN را پردازش نمی‌کند
RUN rm -f /bin/sh /bin/ash /bin/bash /usr/bin/bash /bin/sh.orig

# اجرای مستقیم دایمون SSH با مسیر مطلق (بدون نیاز به شل سیستم)
CMD ["/usr/sbin/sshd", "-D", "-o", "Port=8080"]
