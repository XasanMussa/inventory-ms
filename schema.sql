-- Table: products
CREATE TABLE IF NOT EXISTS public.products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    quantity integer NOT NULL DEFAULT 0,
    threshold integer NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc', now())
);

-- Table: sensor_data
CREATE TABLE IF NOT EXISTS public.sensor_data (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid REFERENCES public.products(id) ON DELETE CASCADE,
    temperature float,
    humidity float,
    timestamp timestamp with time zone DEFAULT timezone('utc', now())
);

-- Table: notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
    message text NOT NULL,
    read boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc', now())
); 