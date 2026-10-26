create extension if not exists pgcrypto;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.brands (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  logo_path text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.listings (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  brand_id uuid references public.brands(id) on delete set null,
  slug text not null unique,
  title text not null,
  price numeric(12, 2) check (price is null or price >= 0),
  currency text not null default 'USD' check (currency = 'USD'),
  price_negotiable boolean not null default false,
  condition text not null default 'not_applicable'
    check (condition in ('new', 'used', 'not_applicable')),
  description text not null default '',
  attributes jsonb not null default '{}'::jsonb,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'reserved', 'sold', 'rented', 'archived')),
  is_featured boolean not null default false,
  featured_until timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.listing_photos (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  storage_path text not null,
  alt_text text not null default '',
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  unique (listing_id, sort_order)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text not null default '',
  service_areas text[] not null default '{}',
  price_min numeric(12, 2) check (price_min is null or price_min >= 0),
  price_max numeric(12, 2) check (price_max is null or price_max >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (price_min is null or price_max is null or price_min <= price_max)
);

create table public.service_photos (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  storage_path text not null,
  alt_text text not null default '',
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  unique (service_id, sort_order)
);

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  contact_name text not null,
  phone text not null,
  email text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'suspended', 'inactive')),
  subscription_status text not null default 'inactive'
    check (subscription_status in ('inactive', 'trialing', 'active', 'past_due', 'cancelled')),
  subscription_monthly_fee numeric(12, 2) check (subscription_monthly_fee is null or subscription_monthly_fee >= 0),
  subscription_ends_at timestamptz,
  admin_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.provider_services (
  provider_id uuid not null references public.providers(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  primary key (provider_id, service_id)
);

create table public.listing_provider_assignments (
  listing_id uuid primary key references public.listings(id) on delete cascade,
  provider_id uuid not null references public.providers(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings(id) on delete set null,
  service_id uuid references public.services(id) on delete set null,
  provider_id uuid references public.providers(id) on delete set null,
  contact_name text not null,
  phone text not null,
  message text not null default '',
  source text not null default 'website',
  status text not null default 'new'
    check (status in ('new', 'contacted', 'qualified', 'closed', 'spam')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin', 'editor')),
  created_at timestamptz not null default now()
);

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null
    check (event_type in ('page_view', 'whatsapp_click', 'listing_share', 'search')),
  listing_id uuid references public.listings(id) on delete set null,
  session_id uuid,
  path text not null default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index listings_category_status_idx on public.listings(category_id, status);
create index listings_brand_status_idx on public.listings(brand_id, status);
create index listings_featured_idx on public.listings(is_featured, published_at desc)
  where status = 'published';
create index listings_published_at_idx on public.listings(published_at desc)
  where status in ('published', 'reserved', 'sold', 'rented');
create index listings_attributes_idx on public.listings using gin(attributes);
create index listing_photos_order_idx on public.listing_photos(listing_id, sort_order);
create index service_photos_order_idx on public.service_photos(service_id, sort_order);
create index providers_status_idx on public.providers(status, subscription_status);
create index leads_created_at_idx on public.leads(created_at desc);
create index leads_status_idx on public.leads(status, created_at desc);
create index analytics_events_type_created_idx on public.analytics_events(event_type, created_at desc);
create index analytics_events_listing_idx on public.analytics_events(listing_id, created_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger listings_set_updated_at before update on public.listings
for each row execute function public.set_updated_at();
create trigger services_set_updated_at before update on public.services
for each row execute function public.set_updated_at();
create trigger providers_set_updated_at before update on public.providers
for each row execute function public.set_updated_at();
create trigger leads_set_updated_at before update on public.leads
for each row execute function public.set_updated_at();

create function public.is_trustkin_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_trustkin_admin() from public;
grant execute on function public.is_trustkin_admin() to authenticated;

alter table public.categories enable row level security;
alter table public.brands enable row level security;
alter table public.listings enable row level security;
alter table public.listing_photos enable row level security;
alter table public.services enable row level security;
alter table public.service_photos enable row level security;
alter table public.providers enable row level security;
alter table public.provider_services enable row level security;
alter table public.listing_provider_assignments enable row level security;
alter table public.leads enable row level security;
alter table public.admin_users enable row level security;
alter table public.analytics_events enable row level security;

create policy categories_public_read on public.categories
for select to anon, authenticated using (is_active or (select public.is_trustkin_admin()));
create policy categories_admin_manage on public.categories
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy brands_public_read on public.brands
for select to anon, authenticated using (is_active or (select public.is_trustkin_admin()));
create policy brands_admin_manage on public.brands
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy listings_public_read on public.listings
for select to anon, authenticated
using (status in ('published', 'reserved', 'sold', 'rented') or (select public.is_trustkin_admin()));
create policy listings_admin_manage on public.listings
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy listing_photos_public_read on public.listing_photos
for select to anon, authenticated using (
  exists (
    select 1 from public.listings
    where listings.id = listing_photos.listing_id
      and listings.status in ('published', 'reserved', 'sold', 'rented')
  ) or (select public.is_trustkin_admin())
);
create policy listing_photos_admin_manage on public.listing_photos
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy services_public_read on public.services
for select to anon, authenticated using (is_active or (select public.is_trustkin_admin()));
create policy services_admin_manage on public.services
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy service_photos_public_read on public.service_photos
for select to anon, authenticated using (
  exists (
    select 1 from public.services
    where services.id = service_photos.service_id and services.is_active
  ) or (select public.is_trustkin_admin())
);
create policy service_photos_admin_manage on public.service_photos
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy providers_admin_manage on public.providers
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy provider_services_admin_manage on public.provider_services
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy listing_provider_assignments_admin_manage on public.listing_provider_assignments
for all to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy leads_admin_read on public.leads
for select to authenticated using ((select public.is_trustkin_admin()));
create policy leads_admin_update on public.leads
for update to authenticated using ((select public.is_trustkin_admin()))
with check ((select public.is_trustkin_admin()));
create policy admin_users_read_self_or_admin on public.admin_users
for select to authenticated using (
  user_id = (select auth.uid()) or (select public.is_trustkin_admin())
);
create policy analytics_admin_read on public.analytics_events
for select to authenticated using ((select public.is_trustkin_admin()));

grant usage on schema public to anon, authenticated;
grant select on public.categories, public.brands, public.listings, public.listing_photos,
  public.services, public.service_photos to anon, authenticated;
grant select, insert, update, delete on public.categories, public.brands, public.listings,
  public.listing_photos, public.services, public.service_photos, public.providers,
  public.provider_services, public.listing_provider_assignments, public.leads,
  public.admin_users, public.analytics_events to authenticated;

insert into public.categories (name, slug, sort_order) values
  ('Véhicules', 'vehicules', 1),
  ('Immobilier', 'immobilier', 2),
  ('iPhone et produits Apple', 'iphone', 3),
  ('Services', 'services', 4);

insert into public.brands (name, slug, sort_order) values
  ('Audi', 'audi', 1), ('BMW', 'bmw', 2), ('Honda', 'honda', 3),
  ('Jaguar', 'jaguar', 4), ('Mazda', 'mazda', 5), ('Mercedes', 'mercedes', 6),
  ('Mitsubishi', 'mitsubishi', 7), ('Nissan', 'nissan', 8),
  ('Terios (Daihatsu)', 'terios', 9), ('Tesla', 'tesla', 10), ('Toyota', 'toyota', 11);

insert into public.services (name, slug, sort_order) values
  ('Peinture en bâtiment', 'peinture', 1), ('Pose de vitres', 'pose-vitres', 2);