-- Migration: Fix notifications.product_id foreign key for Supabase join support

-- Drop the old foreign key constraint if it exists
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_product_id_fkey;

-- Add the correct foreign key constraint
ALTER TABLE public.notifications
ADD CONSTRAINT notifications_product_id_fkey
FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL; 