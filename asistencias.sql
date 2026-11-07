-- Somos Jóvenes LDA · Asistencia por reunión (ejecutar en Supabase → SQL Editor, después de schema.sql)
create table public.asistencias (
  registro_id uuid not null references public.registros(id) on delete cascade,
  fecha date not null,
  creado_en timestamptz not null default now(),
  primary key (registro_id, fecha)          -- un solo escaneo por miembro y por día
);

alter table public.asistencias enable row level security;

create policy "admin lee asistencias" on public.asistencias for select to authenticated using (true);
create policy "admin registra asistencia" on public.asistencias for insert to authenticated with check (true);

revoke all on public.asistencias from anon;
revoke update, delete on public.asistencias from authenticated;

alter publication supabase_realtime add table public.asistencias;
