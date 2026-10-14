-- Issue #2 : "Mes soumissions" affichait les soumissions photo de tous les appareils.
-- À appliquer dans Supabase (SQL Editor) AVANT de publier la version iOS qui appelle la RPC.
-- À VÉRIFIER avant exécution : noms exacts des colonnes de photo_submissions
--   (l'app iOS lit id, box_id, url, status, submitted_at, review_notes ; Android trie sur created_at)
--   et noms des policies existantes : select policyname, cmd, roles from pg_policies where tablename = 'photo_submissions';

-- 1) RPC cloisonnée par appareil, sur le modèle de my_box_submissions
create or replace function public.my_photo_submissions(p_device_token text)
returns table (
  id bigint,
  box_id bigint,
  url text,
  status text,
  submitted_at timestamptz,
  review_notes text
)
language sql
security definer
set search_path = public
as $$
  select ps.id, ps.box_id, ps.url, ps.status, ps.submitted_at, ps.review_notes
  from public.photo_submissions ps
  where p_device_token is not null
    and p_device_token <> ''
    and ps.device_token = p_device_token
  order by ps.submitted_at desc
  limit 200;
$$;

revoke all on function public.my_photo_submissions(text) from public;
grant execute on function public.my_photo_submissions(text) to anon, authenticated;

-- 2) Fermer la lecture anonyme directe de la table (fuite : url + device_token de tout le monde).
--    L'admin (scripts/photo-review-admin-*.mjs) utilise la service_role : non impacté.
--    Remplacer <nom_policy_select_anon> par le nom relevé avec la requête pg_policies ci-dessus.
-- drop policy if exists "<nom_policy_select_anon>" on public.photo_submissions;
-- Contrôle après coup (doit renvoyer [] ou 401) :
--   curl "$SUPABASE_URL/rest/v1/photo_submissions?select=id&limit=1" -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
