ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

REVOKE ALL PRIVILEGES ON TABLE
  public.boards,
  public.entitlements,
  public.newsletter_subscribers,
  public.orders,
  public.products,
  public.profiles
FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.boards TO authenticated;
GRANT SELECT ON TABLE public.entitlements TO authenticated;
GRANT INSERT ON TABLE public.newsletter_subscribers TO anon, authenticated;
GRANT SELECT ON TABLE public.products TO anon, authenticated;
GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT INSERT (id, full_name, updated_at) ON TABLE public.profiles TO authenticated;
GRANT UPDATE (full_name, updated_at) ON TABLE public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.boards,
  public.entitlements,
  public.newsletter_subscribers,
  public.orders,
  public.products,
  public.profiles
TO service_role;

DROP POLICY IF EXISTS "Users can delete own boards" ON public.boards;
DROP POLICY IF EXISTS "Users can insert own boards" ON public.boards;
DROP POLICY IF EXISTS "Users can update own boards" ON public.boards;
DROP POLICY IF EXISTS "Users can view own boards" ON public.boards;
DROP POLICY IF EXISTS "boardie users can create their boards" ON public.boards;
DROP POLICY IF EXISTS "boardie users can delete their boards" ON public.boards;
DROP POLICY IF EXISTS "boardie users can read their boards" ON public.boards;
DROP POLICY IF EXISTS "boardie users can update their boards" ON public.boards;

CREATE POLICY "Users can view own boards"
  ON public.boards FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own boards"
  ON public.boards FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own boards"
  ON public.boards FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own boards"
  ON public.boards FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own entitlements" ON public.entitlements;
CREATE POLICY "Users can view own entitlements"
  ON public.entitlements FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Public can subscribe to newsletter" ON public.newsletter_subscribers;
CREATE POLICY "Public can subscribe to newsletter"
  ON public.newsletter_subscribers FOR INSERT TO anon, authenticated
  WITH CHECK (email = lower(btrim(email)));

DROP POLICY IF EXISTS "Anyone can view active boardie plans" ON public.products;
CREATE POLICY "Anyone can view active boardie plans"
  ON public.products FOR SELECT TO anon, authenticated
  USING (is_active = true);

DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can insert own orders"
  ON public.orders FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

INSERT INTO public.products (
  id, name, description, billing_interval, is_active, sort_order, amount_usd_cents, tier_key
)
VALUES (
  'free', 'Free Beta', 'Free Boardie plan', 'one_time', true, 0, 0, 'free'
)
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = pg_catalog, public
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NULLIF(btrim(NEW.raw_user_meta_data->>'role'), ''), 'creator')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.entitlements (user_id, tier_key, product_id, status)
  VALUES (NEW.id, 'free', 'free', 'active')
  ON CONFLICT (user_id, tier_key) DO NOTHING;

  RETURN NEW;
END;
$function$;

INSERT INTO storage.buckets (id, name, public)
VALUES ('board-attachments', 'board-attachments', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Users can upload their board attachments" ON storage.objects;
CREATE POLICY "Users can upload their board attachments"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'board-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS "Users can update their board attachments" ON storage.objects;
CREATE POLICY "Users can update their board attachments"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'board-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  )
  WITH CHECK (
    bucket_id = 'board-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS "Users can delete their board attachments" ON storage.objects;
CREATE POLICY "Users can delete their board attachments"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'board-attachments'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );
