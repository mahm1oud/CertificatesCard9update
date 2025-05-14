# دليل نشر النظام على VPS مع CyberPanel

## المتطلبات الأساسية

- خادم VPS مع نظام AlmaLinux 9 
- CyberPanel مثبت على الخادم (الإصدار 2.3 أو أعلى)
- Node.js الإصدار 20 أو أعلى
- PostgreSQL الإصدار 14 أو أعلى
- حساب على هوستنجر VPS أو أي مزود استضافة آخر

## الخطوة 1: إعداد البيئة الأساسية

### تثبيت Node.js

```bash
# تحديث النظام أولاً
sudo dnf update -y

# تثبيت Node.js 20
sudo dnf module install -y nodejs:20

# التحقق من الإصدار
node -v
npm -v
```

### تثبيت متطلبات النظام

```bash
# تثبيت متطلبات معالجة الصور والخطوط
sudo dnf install -y cairo cairo-devel pango pango-devel libuuid libuuid-devel libjpeg-turbo libjpeg-turbo-devel giflib-devel

# تثبيت أدوات الضغط والنسخ الاحتياطي والحماية
sudo dnf install -y tar gzip zip unzip wget curl
```

## الخطوة 2: تثبيت وإعداد PostgreSQL

إذا كنت تستخدم قاعدة بيانات خارجية (مثل قاعدة بيانات هوستنجر)، فيمكنك تخطي هذه الخطوة.

```bash
# تثبيت PostgreSQL 14
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql14-server postgresql14-contrib postgresql14-devel

# تهيئة قاعدة البيانات
sudo /usr/pgsql-14/bin/postgresql-14-setup initdb

# بدء تشغيل PostgreSQL وتمكين التشغيل التلقائي
sudo systemctl start postgresql-14
sudo systemctl enable postgresql-14

# التحقق من حالة التشغيل
sudo systemctl status postgresql-14
```

### إنشاء قاعدة البيانات والمستخدم

```bash
# الدخول إلى PostgreSQL
sudo -u postgres psql

# إنشاء المستخدم وقاعدة البيانات
CREATE USER u240955251_colluser WITH PASSWORD '700125733Mm';
CREATE DATABASE u240955251_colliderdb;
GRANT ALL PRIVILEGES ON DATABASE u240955251_colliderdb TO u240955251_colluser;
ALTER USER u240955251_colluser WITH SUPERUSER;

# الخروج من PostgreSQL
\q
```

### تكوين PostgreSQL للسماح بالاتصالات الخارجية (إذا لزم الأمر)

```bash
# تعديل ملف pg_hba.conf
sudo nano /var/lib/pgsql/14/data/pg_hba.conf

# إضافة هذا السطر في نهاية الملف (يسمح بالاتصال من أي عنوان IP)
# host    all             all             0.0.0.0/0               md5

# تعديل ملف postgresql.conf
sudo nano /var/lib/pgsql/14/data/postgresql.conf

# تغيير سطر listen_addresses
# listen_addresses = '*'

# إعادة تشغيل PostgreSQL
sudo systemctl restart postgresql-14
```

## الخطوة 3: نسخ ملفات المشروع

```bash
# إنشاء مجلد للتطبيق في مسار مناسب
sudo mkdir -p /var/www/certificates-app

# تعيين صلاحيات المجلد
sudo chown -R $USER:$USER /var/www/certificates-app

# نسخ ملفات التطبيق
# 1. يمكنك استخدام Git لاستنساخ المشروع مباشرة
git clone https://github.com/your-repository/certificates-app.git /var/www/certificates-app
# أو
# 2. نسخ الملفات المبنية مباشرة من جهازك المحلي

# الانتقال إلى مجلد المشروع
cd /var/www/certificates-app
```

## الخطوة 4: تكوين البيئة وتثبيت التبعيات

```bash
# إنشاء ملف البيئة
cp production.env .env

# تعديل ملف البيئة بمعلومات قاعدة البيانات والإعدادات الأخرى
nano .env

# تثبيت التبعيات
npm ci --production
```

## الخطوة 5: بناء المشروع

```bash
# بناء الجزء الأمامي والخلفي
bash build-deploy.sh

# التحقق من وجود ملفات البناء
ls -la client/dist
ls -la server/dist
```

## الخطوة 6: تثبيت PM2 لإدارة العمليات

```bash
# تثبيت PM2 عالمياً
sudo npm install -g pm2

# تشغيل التطبيق
pm2 start server/dist/index.js --name certificates-app

# ضبط PM2 لبدء التشغيل تلقائياً
pm2 startup
# تنفيذ الأمر الناتج من الأمر السابق
pm2 save
```

## الخطوة 7: إعداد Nginx كبروكسي عكسي

```bash
# تثبيت Nginx (إذا لم يكن مثبتاً بالفعل)
sudo dnf install -y nginx

# إنشاء ملف تكوين للموقع
sudo nano /etc/nginx/conf.d/certificates-app.conf
```

أضف المحتوى التالي:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # زيادة حد حجم تحميل الملفات (إذا لزم الأمر)
    client_max_body_size 10M;
}
```

```bash
# اختبار تكوين Nginx
sudo nginx -t

# إعادة تشغيل Nginx
sudo systemctl restart nginx

# تمكين Nginx للتشغيل عند بدء تشغيل النظام
sudo systemctl enable nginx
```

## الخطوة 8: إعداد Let's Encrypt للحصول على شهادة SSL

إذا كنت تستخدم CyberPanel، فيمكنك إدارة شهادات SSL من واجهة CyberPanel مباشرة.

بدلاً من ذلك، يمكنك استخدام Certbot:

```bash
# تثبيت Certbot
sudo dnf install -y epel-release
sudo dnf install -y certbot python3-certbot-nginx

# الحصول على شهادة SSL وتكوين Nginx تلقائياً
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## الخطوة 9: تأمين الخادم

```bash
# تكوين جدار الحماية
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# فتح المنافذ اللازمة
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# التحقق من حالة جدار الحماية
sudo firewall-cmd --list-all
```

## الخطوة 10: إنشاء نسخ احتياطية دورية

### نسخ احتياطي لقاعدة البيانات

أنشئ سكريبت لعمل نسخ احتياطي لقاعدة البيانات:

```bash
sudo nano /var/www/certificates-app/backup-db.sh
```

أضف المحتوى التالي:

```bash
#!/bin/bash
BACKUP_DIR="/var/www/certificates-app/backups/database"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="u240955251_colliderdb_${TIMESTAMP}.sql"

# إنشاء مجلد النسخ الاحتياطي إذا لم يكن موجوداً
mkdir -p $BACKUP_DIR

# عمل نسخة احتياطية من قاعدة البيانات
pg_dump -U u240955251_colluser u240955251_colliderdb > $BACKUP_DIR/$FILENAME

# ضغط الملف
gzip $BACKUP_DIR/$FILENAME

# الاحتفاظ بآخر 7 نسخ احتياطية فقط
find $BACKUP_DIR -name "*.sql.gz" -type f -mtime +7 -delete
```

```bash
# جعل السكريبت قابلاً للتنفيذ
sudo chmod +x /var/www/certificates-app/backup-db.sh

# إضافة مهمة cron لتشغيل النسخ الاحتياطي يومياً
(crontab -l 2>/dev/null; echo "0 2 * * * /var/www/certificates-app/backup-db.sh") | crontab -
```

## الخطوة 11: مراقبة الأداء

```bash
# تثبيت أدوات المراقبة
sudo dnf install -y htop iotop

# مراقبة استخدام الموارد
htop

# مراقبة سجلات PM2
pm2 logs certificates-app

# مراقبة سجلات Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## استكشاف الأخطاء وإصلاحها

1. **مشكلة في الاتصال بقاعدة البيانات**:
   - تحقق من إعدادات الاتصال في ملف `.env`
   - تأكد من أن خدمة PostgreSQL تعمل: `sudo systemctl status postgresql-14`
   - تحقق من صلاحيات المستخدم: `sudo -u postgres psql -c "\du"`

2. **مشكلة في تشغيل التطبيق**:
   - تحقق من سجلات PM2: `pm2 logs certificates-app`
   - تأكد من تثبيت جميع التبعيات: `npm ci`
   - تحقق من وجود جميع المجلدات المطلوبة مثل `uploads` و `fonts`

3. **مشكلة في عرض الموقع**:
   - تحقق من تكوين Nginx: `sudo nginx -t`
   - تحقق من سجلات Nginx: `sudo tail -f /var/log/nginx/error.log`
   - تأكد من أن Nginx وPM2 يعملان: `sudo systemctl status nginx` و `pm2 status`

## النسخ الاحتياطي والاستعادة

### النسخ الاحتياطي الكامل للتطبيق

```bash
# إنشاء مجلد للنسخ الاحتياطي
mkdir -p /var/backups/certificates-app

# عمل نسخة احتياطية من مجلد التطبيق بالكامل
tar -czf /var/backups/certificates-app/app_backup_$(date +"%Y%m%d").tar.gz /var/www/certificates-app

# عمل نسخة احتياطية من قاعدة البيانات
pg_dump -U u240955251_colluser u240955251_colliderdb > /var/backups/certificates-app/db_backup_$(date +"%Y%m%d").sql
```

### استعادة التطبيق

```bash
# استعادة مجلد التطبيق
tar -xzf /var/backups/certificates-app/app_backup_YYYYMMDD.tar.gz -C /

# استعادة قاعدة البيانات
psql -U u240955251_colluser u240955251_colliderdb < /var/backups/certificates-app/db_backup_YYYYMMDD.sql
```

## خاتمة

هذا الدليل يوفر الخطوات الأساسية لنشر تطبيق شهادات وبطاقات على خادم VPS مع CyberPanel. قد تحتاج إلى تعديل بعض الخطوات بناءً على احتياجاتك الخاصة والإعدادات المحددة لخادمك.

يُنصح بقراءة الملفات المذكورة وتنفيذ الخطوات بعناية، والاحتفاظ بنسخة احتياطية قبل إجراء أي تغييرات كبيرة. إذا واجهت أي مشاكل، فراجع سجلات النظام والتطبيق للمساعدة في تحديد المشكلة وإصلاحها.