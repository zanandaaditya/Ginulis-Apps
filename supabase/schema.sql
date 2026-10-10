-- GINULIS.ID | database sederhana untuk SATU akun pemilik.
-- Jalankan satu kali di Supabase SQL Editor.
-- RLS memastikan akun lain tidak dapat membaca data pesanan.

create extension if not exists pgcrypto;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  name text not null check (length(trim(name)) > 0),
  phone text not null check (length(phone) between 9 and 20),
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique (id, owner_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  customer_id uuid not null,
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  price bigint not null check (price > 0),
  deadline date,
  work_status text not null default 'menunggu'
    check (work_status in ('menunggu','diproses','revisi','selesai','diserahkan','dibatalkan')),
  created_at timestamptz not null default now(),
  unique (id, owner_id),
  constraint orders_customer_owner_fk foreign key (customer_id, owner_id)
    references public.customers(id, owner_id) on delete restrict
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  order_id uuid not null,
  amount bigint not null check (amount > 0),
  method text not null default 'transfer'
    check (method in ('transfer','qris','tunai','lainnya')),
  notes text not null default '',
  paid_at timestamptz not null default now(),
  constraint payments_order_owner_fk foreign key (order_id, owner_id)
    references public.orders(id, owner_id) on delete restrict
);

create index if not exists customers_owner_idx on public.customers(owner_id);
create index if not exists orders_owner_created_idx on public.orders(owner_id, created_at desc);
create index if not exists payments_order_idx on public.payments(order_id, paid_at desc);

alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.payments enable row level security;

create policy "customers_select_owner" on public.customers for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "customers_insert_owner" on public.customers for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "customers_update_owner" on public.customers for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "customers_delete_owner" on public.customers for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy "orders_select_owner" on public.orders for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "orders_insert_owner" on public.orders for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "orders_update_owner" on public.orders for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "orders_delete_owner" on public.orders for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy "payments_select_owner" on public.payments for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "payments_insert_owner" on public.payments for insert to authenticated
  with check (owner_id = (select auth.uid()));

-- Pembayaran merupakan catatan keuangan: tidak disediakan UPDATE/DELETE.
-- Trigger membuat total pembayaran tak bisa melebihi harga pesanan,
-- termasuk jika dua input terjadi hampir bersamaan.
create or replace function public.enforce_payment_amount()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  order_price bigint;
  existing_paid bigint;
  order_owner uuid;
begin
  select price, owner_id into order_price, order_owner
  from public.orders where id = new.order_id for update;

  if not found or order_owner is distinct from auth.uid()
       or new.owner_id is distinct from auth.uid() then
    raise exception 'Pesanan tidak ditemukan atau tidak diizinkan.';
  end if;

  select coalesce(sum(amount), 0) into existing_paid
  from public.payments where order_id = new.order_id;

  if existing_paid + new.amount > order_price then
    raise exception 'Jumlah pembayaran melebihi total pesanan.';
  end if;

  return new;
end;
$$;

drop trigger if exists payments_amount_guard on public.payments;
create trigger payments_amount_guard
before insert on public.payments
for each row execute function public.enforce_payment_amount();

-- Jangan mengubah total harga lebih rendah dari pembayaran yang sudah tercatat.
create or replace function public.enforce_order_total()
returns trigger
language plpgsql
as $$
declare
  total_paid bigint;
begin
  if new.price is distinct from old.price then
    select coalesce(sum(amount), 0) into total_paid
    from public.payments where order_id = new.id;
    if new.price < total_paid then
      raise exception 'Harga baru tidak boleh kurang dari pembayaran yang sudah tercatat.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_price_guard on public.orders;
create trigger orders_price_guard
before update of price on public.orders
for each row execute function public.enforce_order_total();

-- Jangan gunakan service_role key di aplikasi Flutter.
-- Akun pemilik dibuat manual di Supabase > Authentication > Users.
