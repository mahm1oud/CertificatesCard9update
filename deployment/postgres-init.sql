-- سكريبت تهيئة قاعدة البيانات PostgreSQL
-- يتم تنفيذ هذا السكريبت مرة واحدة عند إعداد قاعدة البيانات

-- إنشاء المستخدم وقاعدة البيانات
CREATE USER u240955251_colluser WITH PASSWORD '700125733Mm';
CREATE DATABASE u240955251_colliderdb;
ALTER DATABASE u240955251_colliderdb OWNER TO u240955251_colluser;

-- منح الصلاحيات الكاملة على قاعدة البيانات
GRANT ALL PRIVILEGES ON DATABASE u240955251_colliderdb TO u240955251_colluser;

-- اتصال بقاعدة البيانات
\c u240955251_colliderdb;

-- منح الصلاحيات على جميع الجداول والمخططات والتسلسلات
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO u240955251_colluser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO u240955251_colluser;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO u240955251_colluser;
GRANT ALL PRIVILEGES ON SCHEMA public TO u240955251_colluser;

-- منح صلاحيات المالك للمستخدم
ALTER DATABASE u240955251_colliderdb OWNER TO u240955251_colluser;

-- تعيين المستخدم كمالك لجميع الأشياء في المخطط العام (public)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO u240955251_colluser;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES TO u240955251_colluser;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON FUNCTIONS TO u240955251_colluser;

-- منح صلاحيات الإنشاء في المخطط العام
GRANT CREATE ON SCHEMA public TO u240955251_colluser;

-- تعيين المستخدم كمشرف على قاعدة البيانات (اختياري، للسماح بإنشاء قواعد بيانات جديدة وأدوار)
ALTER USER u240955251_colluser WITH SUPERUSER;

-- اتصال بقاعدة البيانات المنشأة
\c u240955251_colliderdb;

-- إنشاء الامتدادات المطلوبة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ضبط إعدادات المنطقة الزمنية
SET timezone = 'UTC';

-- تنفيذ سكريبت نسخة احتياطية من قاعدة البيانات (اختياري)
-- \i backup.sql

-- ملاحظة: سيتم إنشاء الجداول وترحيلها باستخدام Drizzle ORM عند بدء التشغيل الأول للتطبيق