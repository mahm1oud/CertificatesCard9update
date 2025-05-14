# دليل نشر تطبيق الشهادات والبطاقات الإلكترونية
# Certificates & Cards Application Deployment Guide

## مقدمة | Introduction

هذا الدليل يشرح كيفية نشر تطبيق الشهادات والبطاقات الإلكترونية على الإنترنت، سواء على خادم VPS أو استضافة مشتركة تدعم Node.js، مع التركيز على نشره عبر CyberPanel على نظام AlmaLinux 9.

This guide explains how to deploy the Certificates & Cards application on the internet, whether on a VPS server or shared hosting that supports Node.js, with a focus on deploying it through CyberPanel on AlmaLinux 9.

## المتطلبات الأساسية | Prerequisites

- خادم يعمل بنظام AlmaLinux 9 (أو أي توزيعة Linux أخرى)
- وصول SSH للخادم
- النطاق (Domain) موجه للخادم
- CyberPanel مثبت على الخادم (اختياري، ولكن موصى به)

---

- A server running AlmaLinux 9 (or any other Linux distribution)
- SSH access to the server
- Domain pointed to the server
- CyberPanel installed on the server (optional, but recommended)

## خيارات النشر | Deployment Options

### 1. النشر على CyberPanel (موصى به) | CyberPanel Deployment (Recommended)

يوفر CyberPanel واجهة سهلة الاستخدام لإدارة الخادم ومواقع الويب وشهادات SSL. للحصول على تعليمات مفصلة، راجع ملف `deployment/cyberpanel-deployment.md`.

CyberPanel provides an easy-to-use interface for managing the server, websites, and SSL certificates. For detailed instructions, see the `deployment/cyberpanel-deployment.md` file.

### 2. النشر المباشر على VPS | Direct VPS Deployment

إذا كنت تفضل النشر مباشرة على VPS بدون استخدام CyberPanel، يمكنك استخدام Nginx كـ reverse proxy مع PM2 لإدارة عمليات Node.js. راجع ملف `deployment/vps-deployment.md` للحصول على تعليمات.

If you prefer to deploy directly on a VPS without using CyberPanel, you can use Nginx as a reverse proxy with PM2 to manage Node.js processes. See the `deployment/vps-deployment.md` file for instructions.

### 3. النشر على Replit | Replit Deployment

يمكن نشر التطبيق أيضًا على منصة Replit، وهي مناسبة للاختبار والتطوير. انظر إلى ملف `DEPLOY.md` للتعليمات.

The application can also be deployed on the Replit platform, which is suitable for testing and development. See the `DEPLOY.md` file for instructions.

## خطوات بناء المشروع | Project Build Steps

قبل النشر، يجب بناء المشروع. يمكنك استخدام سكريبتات البناء المتوفرة:

Before deployment, you need to build the project. You can use the available build scripts:

### بناء المشروع الكامل | Building the Entire Project

```bash
./build-all.sh
```

### بناء الواجهة الأمامية فقط | Building the Frontend Only

```bash
./build-client.sh
```

### بناء الخادم فقط | Building the Backend Only

```bash
./build-server.sh
```

## إعداد قاعدة البيانات | Database Setup

التطبيق يستخدم PostgreSQL كقاعدة بيانات. يجب إعداد قاعدة البيانات قبل تشغيل التطبيق:

The application uses PostgreSQL as a database. You need to set up the database before running the application:

```bash
# تثبيت PostgreSQL
# Install PostgreSQL
sudo dnf module install -y postgresql:15/server

# بدء تشغيل الخدمة
# Start the service
systemctl enable postgresql
systemctl start postgresql

# إنشاء قاعدة البيانات والمستخدم
# Create database and user
sudo -i -u postgres
psql -c "CREATE USER u240955251_colluser WITH PASSWORD '700125733Mm';"
psql -c "CREATE DATABASE u240955251_colliderdb;"
psql -c "ALTER DATABASE u240955251_colliderdb OWNER TO u240955251_colluser;"
psql -c "GRANT ALL PRIVILEGES ON DATABASE u240955251_colliderdb TO u240955251_colluser;"
```

## إعدادات البيئة | Environment Settings

يجب إنشاء ملف `.env` في جذر المشروع بناءً على ملف `production.env` المتوفر. تأكد من تحديث القيم حسب بيئتك:

You need to create a `.env` file in the project root based on the provided `production.env` file. Make sure to update the values according to your environment:

```
NODE_ENV=production
PORT=5000

# إعدادات قاعدة البيانات PostgreSQL
# PostgreSQL Database Settings
DATABASE_URL=postgresql://u240955251_colluser:700125733Mm@localhost:5432/u240955251_colliderdb

# مسار السيرفر
# Server URL
SERVER_URL=https://your-domain.com

# إعدادات أخرى
# Other settings
UPLOAD_DIR=/path/to/uploads
SESSION_SECRET=your_secret_key
JWT_SECRET=your_jwt_secret
```

## إعدادات الويب سيرفر | Web Server Configuration

### Nginx (مع CyberPanel أو بدونه) | Nginx (with or without CyberPanel)

يتوفر ملف تكوين نموذجي لـ Nginx في `deployment/nginx-config.conf`. قم بتعديله ليناسب نطاقك.

A sample Nginx configuration file is available in `deployment/nginx-config.conf`. Modify it to suit your domain.

### إعداد خدمة Systemd | Systemd Service Setup

لتشغيل التطبيق كخدمة في الخلفية، استخدم ملف خدمة systemd المتوفر في `deployment/systemd-service.service`:

To run the application as a background service, use the systemd service file available in `deployment/systemd-service.service`:

```bash
cp deployment/systemd-service.service /etc/systemd/system/certificates-app.service
systemctl daemon-reload
systemctl enable certificates-app
systemctl start certificates-app
```

## إعدادات SSL | SSL Configuration

للحصول على شهادة SSL مجانية من Let's Encrypt، يمكنك استخدام CyberPanel الذي يوفر دعمًا مدمجًا، أو استخدام Certbot:

To get a free SSL certificate from Let's Encrypt, you can use CyberPanel which provides built-in support, or use Certbot:

```bash
dnf install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com -d www.your-domain.com
```

## استكشاف الأخطاء وإصلاحها | Troubleshooting

### مشاكل اتصال قاعدة البيانات | Database Connection Issues

تأكد من أن خدمة PostgreSQL تعمل وأن إعدادات الاتصال صحيحة في ملف `.env`.

Make sure the PostgreSQL service is running and that the connection settings are correct in the `.env` file.

### مشاكل الأذونات | Permission Issues

تأكد من أن المستخدم الذي يشغل التطبيق لديه أذونات صحيحة لقراءة/كتابة المجلدات المطلوبة:

Ensure that the user running the application has the correct permissions to read/write the required directories:

```bash
chown -R user:group /path/to/app/uploads
chmod -R 755 /path/to/app/uploads
```

### مشاكل Nginx | Nginx Issues

تحقق من سجلات أخطاء Nginx:

Check Nginx error logs:

```bash
tail -f /var/log/nginx/error.log
```

### مشاكل التطبيق | Application Issues

تحقق من سجلات التطبيق:

Check application logs:

```bash
journalctl -u certificates-app -f
```

## النسخ الاحتياطي | Backup

لإعداد نسخ احتياطي يومي للتطبيق وقاعدة البيانات، راجع ملف `deployment/cyberpanel-deployment.md` للحصول على سكريبت النسخ الاحتياطي.

To set up daily backups for the application and database, refer to the `deployment/cyberpanel-deployment.md` file for the backup script.

## التحديث | Updating

لتحديث التطبيق إلى إصدار جديد:

To update the application to a new version:

```bash
cd /path/to/app
git pull
./build-all.sh
systemctl restart certificates-app
```

## الدعم | Support

إذا واجهت أي مشاكل، يرجى:
1. مراجعة ملفات التوثيق في مجلد `deployment/`
2. التحقق من سجلات التطبيق وسجلات Nginx
3. التواصل مع فريق الدعم من خلال البريد الإلكتروني المتوفر في ملف `README.md`

If you encounter any issues, please:
1. Review the documentation files in the `deployment/` folder
2. Check the application logs and Nginx logs
3. Contact the support team through the email available in the `README.md` file