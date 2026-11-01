-- Skema awal PostgreSQL ZENTRIX; bukan database aktif sampai dipasang ke server.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TYPE order_status AS ENUM ('pending_payment','paid','processing','success','failed','expired','refunded','manual_review');
CREATE TABLE customers(id UUID PRIMARY KEY DEFAULT gen_random_uuid(), phone TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE games(id TEXT PRIMARY KEY,name TEXT NOT NULL,enabled BOOLEAN DEFAULT true,logo_url TEXT,sort_order INT DEFAULT 0);
CREATE TABLE products(id TEXT PRIMARY KEY,game_id TEXT REFERENCES games(id),name TEXT NOT NULL,supplier_code TEXT,base_price INT,sell_price INT,enabled BOOLEAN DEFAULT false,CHECK(base_price IS NULL OR base_price>=0),CHECK(sell_price IS NULL OR sell_price>=0));
CREATE TABLE orders(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),invoice TEXT UNIQUE NOT NULL,customer_id UUID REFERENCES customers(id),game_id TEXT REFERENCES games(id),product_id TEXT REFERENCES products(id),account_data JSONB NOT NULL,amount INT NOT NULL CHECK(amount>0),status order_status DEFAULT 'pending_payment',payment_provider TEXT,payment_reference TEXT UNIQUE,supplier_provider TEXT,supplier_reference TEXT UNIQUE,failure_reason TEXT,created_at TIMESTAMPTZ DEFAULT now(),updated_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE payment_events(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),provider TEXT NOT NULL,event_id TEXT NOT NULL,order_id UUID REFERENCES orders(id),payload JSONB NOT NULL,received_at TIMESTAMPTZ DEFAULT now(),UNIQUE(provider,event_id));
CREATE TABLE supplier_events(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),provider TEXT NOT NULL,event_id TEXT NOT NULL,order_id UUID REFERENCES orders(id),payload JSONB NOT NULL,received_at TIMESTAMPTZ DEFAULT now(),UNIQUE(provider,event_id));
CREATE TABLE refunds(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),order_id UUID REFERENCES orders(id),amount INT NOT NULL CHECK(amount>0),reason TEXT NOT NULL,status TEXT DEFAULT 'requested',provider_reference TEXT,created_at TIMESTAMPTZ DEFAULT now());
CREATE TABLE audit_logs(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),actor_id TEXT,action TEXT NOT NULL,entity TEXT NOT NULL,entity_id TEXT NOT NULL,details JSONB,created_at TIMESTAMPTZ DEFAULT now());
CREATE INDEX orders_created_idx ON orders(created_at DESC); CREATE INDEX orders_status_idx ON orders(status);
-- Produksi wajib: autentikasi admin, RLS/izin akses, webhook signature, idempotensi, rate limit, backup.
