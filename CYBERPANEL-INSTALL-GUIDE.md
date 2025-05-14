# دليل تثبيت التطبيق على CyberPanel

## المقدمة

يوفر هذا الدليل خطوات تفصيلية لتثبيت تطبيق الشهادات والبطاقات الإلكترونية على خادم مع CyberPanel و AlmaLinux 9. CyberPanel هو لوحة تحكم مجانية ومفتوحة المصدر تسهل إدارة خادم الويب الخاص بك.

## المتطلبات الأساسية

- خادم VPS مع AlmaLinux 9
- CyberPanel مثبت ومكوّن
- امتيازات المستخدم root أو sudo

## الخطوة 1: تثبيت CyberPanel

إذا لم يكن CyberPanel مثبتاً بالفعل، يمكنك تثبيته باستخدام الأمر التالي:

```bash
sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)
```

خلال عملية التثبيت، اختر OpenLiteSpeed (الخيار الافتراضي) ثم اتبع التعليمات على الشاشة.

## الخطوة 2: إنشاء موقع في CyberPanel

1. قم بتسجيل الدخول إلى لوحة تحكم CyberPanel (عادة على المنفذ 8090)
2. انتقل إلى "Websites" > "Create Website"
3. أدخل اسم النطاق (مثل certificates.yourdomain.com)
4. اختر نفس حزمة الاستضافة ومالك الموقع أو قم بإنشاء جديد
5. انقر على "Create Website"

## الخطوة 3: تثبيت Node.js و PostgreSQL

### تثبيت Node.js:

```bash
# تثبيت Node.js 20
sudo dnf module install -y nodejs:20

# التحقق من التثبيت
node -v
npm -v
```

### تثبيت PostgreSQL:

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
```

## الخطوة 4: تكوين PostgreSQL

```bash
# الدخول كمستخدم postgres
sudo -i -u postgres

# بدء جلسة psql
psql

# إنشاء مستخدم وقاعدة بيانات
CREATE USER u240955251_colluser WITH PASSWORD '700125733Mm';
CREATE DATABASE u240955251_colliderdb;
GRANT ALL PRIVILEGES ON DATABASE u240955251_colliderdb TO u240955251_colluser;
ALTER USER u240955251_colluser WITH SUPERUSER;

# الخروج من psql
\q

# العودة للمستخدم العادي
exit
```

## الخطوة 5: تثبيت المتطلبات الإضافية

```bash
# تثبيت متطلبات معالجة الصور والخطوط
sudo dnf install -y cairo cairo-devel pango pango-devel libuuid libuuid-devel libjpeg-turbo libjpeg-turbo-devel giflib-devel

# تثبيت أدوات أخرى مفيدة
sudo dnf install -y tar gzip zip unzip wget curl git
```

## الخطوة 6: تجهيز دليل التطبيق

CyberPanel ينشئ هيكل مجلدات معين لكل موقع. يجب وضع التطبيق في المكان المناسب:

```bash
# الانتقال إلى دليل المستخدم للموقع
cd /home/example.com/public_html

# مسح أي ملفات موجودة (احتياطياً)
sudo mv index.html index.html.bak

# إنشاء المجلدات اللازمة
mkdir -p uploads fonts logs
```

## الخطوة 7: نسخ ملفات التطبيق

هناك طريقتان لنسخ ملفات التطبيق:

### الطريقة 1: نسخ ملفات مبنية مسبقاً

```bash
# نسخ حزمة التطبيق المبنية إلى الخادم
# (يجب تنفيذ هذا الأمر على جهازك المحلي)
scp certificates-app-YYYYMMDD_HHMMSS.tar.gz root@your-server-ip:/home/example.com/public_html/

# على الخادم، فك ضغط الحزمة
cd /home/example.com/public_html
tar -xzf certificates-app-YYYYMMDD_HHMMSS.tar.gz
```

### الطريقة 2: استنساخ من Git واستخدام سكريبت البناء

```bash
# استنساخ المستودع
git clone https://github.com/your-repository/certificates-app.git /tmp/certificates-app

# نسخ الملفات إلى المجلد المناسب
cp -r /tmp/certificates-app/* /home/example.com/public_html/

# تثبيت التبعيات
cd /home/example.com/public_html
npm ci --production

# تنفيذ سكريبت البناء
bash build-deploy.sh
```

## الخطوة 8: تكوين متغيرات البيئة

```bash
# نسخ ملف البيئة
cp production.env .env

# تعديل الملف إذا لزم الأمر
nano .env
```

## الخطوة 9: تثبيت PM2 وإعداد التطبيق كخدمة

```bash
# تثبيت PM2 عالمياً
sudo npm install -g pm2

# بدء تشغيل التطبيق
cd /home/example.com/public_html
pm2 start server/dist/index.js --name certificates-app

# ضبط PM2 لبدء التشغيل تلقائياً
pm2 startup
# تنفيذ الأمر الذي يظهر في النتيجة

# حفظ التكوين الحالي
pm2 save
```

## الخطوة 10: تكوين OpenLiteSpeed كبروكسي عكسي

على CyberPanel:

1. انتقل إلى "Websites" > [اسم موقعك] > "Rewrite Rules"
2. انقر على "Add Rewrite Rule"
3. أدخل المعلومات التالية:
   - Rule Name: NodeAppProxy
   - Domain: example.com (النطاق الخاص بك)
   - وفي قسم Rewrite Rule، أدخل:

```
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/static
RewriteCond %{REQUEST_URI} !^/.well-known
RewriteRule ^(.*)$ http://localhost:5000$1 [P,L]
```

4. انقر على "Save Rewrite Rule"

## الخطوة 11: إعداد شهادة SSL

1. انتقل إلى "Websites" > [اسم موقعك] > "SSL"
2. اختر "Issue SSL" واختر موفر SSL المناسب (Let's Encrypt أو Comodo)
3. اتبع التعليمات لإكمال إصدار شهادة SSL

## الخطوة 12: التحقق من التثبيت

بعد الانتهاء من جميع الخطوات، يمكنك التحقق من أن التطبيق يعمل بشكل صحيح:

```bash
# التحقق من حالة PM2
pm2 status

# التحقق من سجلات التطبيق
pm2 logs certificates-app

# التحقق من إمكانية الوصول إلى الخادم
curl http://localhost:5000
```

## الخطوة 13: إعداد النسخ الاحتياطي

لإعداد نسخ احتياطي تلقائي:

1. أنشئ سكريبت النسخ الاحتياطي:

```bash
sudo nano /home/example.com/public_html/backup.sh
```

2. أضف المحتوى التالي:

```bash
#!/bin/bash
BACKUP_DIR="/home/example.com/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APP_DIR="/home/example.com/public_html"
DB_NAME="u240955251_colliderdb"
DB_USER="u240955251_colluser"

# إنشاء المجلدات
mkdir -p ${BACKUP_DIR}/{db,files}

# نسخ احتياطي لقاعدة البيانات
pg_dump -U ${DB_USER} ${DB_NAME} > ${BACKUP_DIR}/db/${DB_NAME}_${TIMESTAMP}.sql

# ضغط ملفات التطبيق
tar -czf ${BACKUP_DIR}/files/app_backup_${TIMESTAMP}.tar.gz ${APP_DIR} --exclude=${APP_DIR}/node_modules --exclude=${APP_DIR}/.git

# حذف النسخ الاحتياطية القديمة (أكثر من 7 أيام)
find ${BACKUP_DIR}/db -name "*.sql" -type f -mtime +7 -delete
find ${BACKUP_DIR}/files -name "*.tar.gz" -type f -mtime +7 -delete
```

3. اجعل السكريبت قابلاً للتنفيذ:

```bash
sudo chmod +x /home/example.com/public_html/backup.sh
```

4. أضف مهمة cron لتشغيل النسخ الاحتياطي:

```bash
(crontab -l 2>/dev/null; echo "0 2 * * * /home/example.com/public_html/backup.sh") | crontab -
```

## استكشاف الأخطاء وإصلاحها

### التطبيق لا يعمل

1. تحقق من سجلات PM2:
   ```bash
   pm2 logs certificates-app
   ```

2. تأكد من أن المنفذ 5000 مفتوح ومتاح:
   ```bash
   netstat -tulpn | grep 5000
   ```

3. تحقق من تكوين الوكيل العكسي في OpenLiteSpeed:
   ```bash
   cat /usr/local/lsws/conf/vhosts/example.com/htaccess.conf
   ```

### مشاكل قاعدة البيانات

1. تحقق من اتصال قاعدة البيانات:
   ```bash
   psql -U u240955251_colluser -d u240955251_colliderdb -c "SELECT 1"
   ```

2. تأكد من أن الجداول موجودة:
   ```bash
   psql -U u240955251_colluser -d u240955251_colliderdb -c "\dt"
   ```

### مشاكل التصاريح

قد تواجه مشاكل في التصاريح خاصة مع مجلدات التحميل والخطوط:

```bash
# ضبط التصاريح الصحيحة
sudo chown -R nobody:nobody /home/example.com/public_html/uploads
sudo chown -R nobody:nobody /home/example.com/public_html/fonts
sudo chmod -R 755 /home/example.com/public_html/uploads
sudo chmod -R 755 /home/example.com/public_html/fonts
```

## الخاتمة

يوفر هذا الدليل الخطوات الأساسية لتثبيت وتكوين تطبيق الشهادات والبطاقات الإلكترونية على خادم مع CyberPanel. قد تحتاج إلى تعديل بعض الخطوات بناءً على إعداداتك الخاصة وتكوين خادمك.