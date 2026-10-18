-- BudgetZlate: tabla de gastos con Row Level Security (RLS).
--
-- Cómo aplicarlo: copiar todo este archivo en Supabase → SQL Editor → Run.
-- Se puede ejecutar más de una vez sin error (usa "if not exists" / "drop ... if exists").

-- 1. Tabla ------------------------------------------------------------------

create table if not exists public.gastos (
  id uuid primary key default gen_random_uuid(),
  -- Dueño del gasto. Por defecto, el usuario que hace la petición.
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  descripcion text not null check (length(trim(descripcion)) > 0),
  -- Céntimos de colón: ₡1 500,50 => 150050. Entero para no perder precisión.
  monto_centimos bigint not null check (monto_centimos > 0),
  categoria text not null
    check (categoria in ('alimentacion', 'transporte', 'servicios', 'otros')),
  fecha date not null,
  creado_en timestamptz not null default now()
);

-- Acelera "los gastos de este usuario, ordenados por fecha".
create index if not exists gastos_user_id_fecha_idx
  on public.gastos (user_id, fecha desc);

-- 2. Permisos ---------------------------------------------------------------
-- Solo los usuarios con sesión (rol "authenticated") pueden usar la tabla;
-- sin sesión (rol "anon") no hay acceso. RLS decide además QUÉ filas.

revoke all on public.gastos from anon;
grant select, insert, update, delete on public.gastos to authenticated;

-- 3. Row Level Security -----------------------------------------------------
-- Con RLS activo, una fila solo es visible o modificable si alguna política
-- lo permite. Sin políticas, nadie (salvo el administrador) ve nada.

alter table public.gastos enable row level security;

-- "(select auth.uid())" en lugar de "auth.uid()": Postgres lo calcula una
-- vez por consulta y no una vez por fila (recomendación de Supabase).

drop policy if exists "leer propios" on public.gastos;
create policy "leer propios" on public.gastos
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "crear propios" on public.gastos;
create policy "crear propios" on public.gastos
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "actualizar propios" on public.gastos;
create policy "actualizar propios" on public.gastos
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "eliminar propios" on public.gastos;
create policy "eliminar propios" on public.gastos
  for delete to authenticated
  using ((select auth.uid()) = user_id);
