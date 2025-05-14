# دليل نشر التطبيق على CyberPanel

هذا الدليل يشرح كيفية نشر تطبيق الشهادات والبطاقات الإلكترونية على خادم CyberPanel المثبت على AlmaLinux 9.

## المتطلبات

- خادم يعمل بنظام AlmaLinux 9
- CyberPanel مُثبت على الخادم
- نطاق مُسجل وموجه للخادم
- وصول SSH للخادم

## الخطوة 1: تثبيت Node.js وPostgreSQL

```bash
# تثبيت Node.js 20
dnf module install -y nodejs:20/common

# تثبيت PostgreSQL 15
dnf module install -y postgresql:15/server

# تثبيت أدوات إضافية
dnf install -y git wget unzip
```

## الخطوة 2: إعداد قاعدة بيانات PostgreSQL

```bash
# بدء تشغيل خدمة PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# تسجيل الدخول كمستخدم postgres
sudo -i -u postgres

# إنشاء قاعدة البيانات والمستخدم
psql -c "CREATE USER u240955251_colluser WITH PASSWORD '700125733Mm';"
psql -c "CREATE DATABASE u240955251_colliderdb;"
psql -c "ALTER DATABASE u240955251_colliderdb OWNER TO u240955251_colluser;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE u240955251_colliderdb TO u240955251_colluser;"
psql -c "ALTER USER u240955251_colluser WITH SUPERUSER;"

# إنشاء الجداول الأساسية
psql -d u240955251_colliderdb -a -f /var/www/certificates-app/deployment/postgres-init.sql

# الخروج من مستخدم postgres
exit
```

## الخطوة 3: تنزيل التطبيق وإعداده

```bash
# انتقل إلى المجلد الرئيسي
cd /var/www/

# استنساخ المستودع من GitHub
git clone https://github.com/mahm1oud/CertificatesCard9update.git certificates-app

# الانتقال إلى مجلد التطبيق
cd certificates-app

# تثبيت اعتماديات التطبيق
npm install

# نسخ ملف البيئة الإنتاجية
cp production.env .env
```

## الخطوة 4: تعديل ملف .env لإعدادات البيئة الإنتاجية

قم بتعديل ملف `.env` ليحتوي على البيانات التالية:

```
NODE_ENV=production
PORT=5000

# إعدادات قاعدة البيانات PostgreSQL
DATABASE_URL=postgresql://u240955251_colluser:700125733Mm@localhost:5432/u240955251_colliderdb

# مسار السيرفر
SERVER_URL=https://example.com

# مسار تخزين الملفات المرفوعة
UPLOAD_DIR=/var/www/certificates-app/uploads

# إعدادات السيشن
SESSION_SECRET=your_strong_session_secret_key_here
SESSION_MAX_AGE=86400000

# إعدادات JWT
JWT_SECRET=your_strong_jwt_secret_key_here
JWT_EXPIRES_IN=24h

# مسار مجلد الخطوط العربية
FONTS_DIR=/var/www/certificates-app/fonts

# إعدادات بريد الإشعارات (اختياري)
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USER=user@example.com
MAIL_PASS=your_mail_password
MAIL_FROM=noreply@example.com
```

## الخطوة 5: بناء التطبيق للإنتاج

```bash
# بناء التطبيق (الواجهة الأمامية والخادم)
npm run build:all

# إنشاء المجلدات المطلوبة
mkdir -p uploads/logos uploads/signatures uploads/certificates uploads/temp
chmod -R 755 uploads
```

## الخطوة 6: إعداد خدمة systemd

```bash
# نسخ ملف خدمة systemd
cp deployment/systemd-service.service /etc/systemd/system/certificates-app.service

# تحديث النظام ليتعرف على الخدمة الجديدة
systemctl daemon-reload

# تشغيل الخدمة وجعلها تعمل تلقائياً عند إعادة تشغيل الخادم
systemctl enable certificates-app
systemctl start certificates-app

# التحقق من حالة الخدمة
systemctl status certificates-app
```

## الخطوة 7: إعداد Nginx من خلال CyberPanel

1. قم بتسجيل الدخول إلى لوحة تحكم CyberPanel
2. انتقل إلى Websites > Create Website
3. أنشئ موقع ويب جديد باستخدام النطاق الخاص بك (example.com)
4. انتقل إلى Websites > List Websites
5. اختر موقع الويب الخاص بك ثم انقر على "Manage"
6. انتقل إلى "vHosts File" وحرر ملف التكوين
7. استبدل محتوى الملف بمحتوى ملف `deployment/nginx-config.conf` مع تعديل اسم النطاق
8. احفظ التغييرات وأعد تشغيل Nginx:

```bash
systemctl restart nginx
```

## الخطوة 8: تمكين HTTPS مع Let's Encrypt

1. في لوحة تحكم CyberPanel، انتقل إلى "SSL" ضمن قسم إدارة موقع الويب
2. اختر "Issue SSL" للحصول على شهادة SSL مجانية من Let's Encrypt
3. اتبع التعليمات لإصدار شهادة SSL لنطاقك

## الخطوة 9: التحقق من التثبيت

```bash
# التأكد من حالة التطبيق
systemctl status certificates-app

# مراجعة سجلات التطبيق
journalctl -u certificates-app -f

# التحقق من وصول Nginx إلى التطبيق
curl http://localhost:5000/api/health
```

## الخطوة 10: إعداد النسخ الاحتياطي اليومي

```bash
# إنشاء سكريبت النسخ الاحتياطي
cat > /root/backup-certificates-app.sh << 'EOL'
#!/bin/bash
BACKUP_DIR="/root/backups/certificates-app"
DATE=$(date +%Y-%m-%d)
DB_BACKUP="$BACKUP_DIR/db-$DATE.sql"
APP_BACKUP="$BACKUP_DIR/app-$DATE.tar.gz"

# إنشاء مجلد النسخ الاحتياطي إذا لم يكن موجودًا
mkdir -p $BACKUP_DIR

# نسخ احتياطي لقاعدة البيانات
pg_dump -U postgres -d u240955251_colliderdb > $DB_BACKUP

# ضغط ملفات التطبيق
tar -czf $APP_BACKUP /var/www/certificates-app

# حذف النسخ الاحتياطية الأقدم من 7 أيام
find $BACKUP_DIR -name "*.sql" -type f -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -type f -mtime +7 -delete
EOL

# جعل السكريبت قابل للتنفيذ
chmod +x /root/backup-certificates-app.sh

# إضافة مهمة cron للتشغيل اليومي الساعة 2 صباحًا
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup-certificates-app.sh") | crontab -
```

## استكشاف الأخطاء وإصلاحها

### التطبيق لا يعمل

```bash
# تحقق من سجلات التطبيق
journalctl -u certificates-app -f

# تأكد من تشغيل الخدمة
systemctl status certificates-app

# اختبر التطبيق يدويًا
cd /var/www/certificates-app
node server/index.js
```

### مشاكل قاعدة البيانات

```bash
# تحقق من اتصال قاعدة البيانات
sudo -u postgres psql -d u240955251_colliderdb -c "SELECT 1;"

# إعادة تشغيل خدمة PostgreSQL
systemctl restart postgresql
```

### مشاكل Nginx

```bash
# تحقق من حالة Nginx
systemctl status nginx

# تحقق من أخطاء التكوين
nginx -t

# اختبر التطبيق محليًا
curl http://localhost:5000/api/health
```

## تحديث التطبيق

```bash
# انتقل إلى مجلد التطبيق
cd /var/www/certificates-app

# سحب أحدث التغييرات
git pull

# تثبيت أي اعتماديات جديدة
npm install

# إعادة بناء التطبيق
npm run build:all

# إعادة تشغيل الخدمة
systemctl restart certificates-app
```