-- Somos Jóvenes LDA · Ejecutar completo en Supabase → SQL Editor
create table public.registros (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  email text not null,
  telefono text,
  estado text not null default 'pendiente' check (estado in ('pendiente','confirmado')),
  creado_en timestamptz not null default now(),
  confirmado_en timestamptz
  -- , unique (email)  -- descomenta para impedir correos duplicados
);

alter table public.registros enable row level security;

-- Solo usuarios autenticados (admin) pueden leer y confirmar
create policy "admin lee" on public.registros for select to authenticated using (true);
create policy "admin confirma" on public.registros for update to authenticated
  using (true) with check (estado = 'confirmado');

-- El público no toca la tabla; el admin solo puede modificar "estado"
revoke all on public.registros from anon;
revoke insert, delete, update on public.registros from authenticated;
grant update (estado) on public.registros to authenticated;

-- Fecha de confirmación puesta por el servidor
create or replace function public.set_confirmado_en() returns trigger language plpgsql as $$
begin
  if new.estado = 'confirmado' and old.estado = 'pendiente' then new.confirmado_en := now(); end if;
  return new;
end $$;
create trigger trg_confirmado before update on public.registros
  for each row execute function public.set_confirmado_en();

-- Registro público: inserta y devuelve únicamente el UUID
create or replace function public.registrar_usuario(p_nombre text, p_email text, p_telefono text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  insert into registros (nombre, email, telefono) values (p_nombre, p_email, p_telefono)
  returning id into v_id;
  return v_id;
end $$;
grant execute on function public.registrar_usuario to anon;

-- Tiempo real
alter publication supabase_realtime add table public.registros;
