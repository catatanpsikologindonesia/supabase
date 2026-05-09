ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS client_ip text; ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS user_agent text;
