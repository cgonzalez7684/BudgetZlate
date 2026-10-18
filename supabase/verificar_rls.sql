-- BudgetZlate: comprobaciones de la tabla gastos (ejecutar en SQL Editor).
-- Solo lee; no modifica nada.

-- 1. RLS activo: debe devolver rls_activo = true.
select relname as tabla, relrowsecurity as rls_activo
from pg_class
where oid = 'public.gastos'::regclass;

-- 2. Políticas: deben aparecer 4 (SELECT, INSERT, UPDATE, DELETE),
--    todas para el rol authenticated.
select policyname as politica, cmd as operacion, roles
from pg_policies
where schemaname = 'public' and tablename = 'gastos'
order by cmd;

-- 3. Gastos por usuario (el SQL Editor es administrador y ve todo):
--    sirve para comparar con lo que ve cada usuario en la app.
select u.email, count(g.id) as gastos
from auth.users u
left join public.gastos g on g.user_id = u.id
group by u.email
order by u.email;
