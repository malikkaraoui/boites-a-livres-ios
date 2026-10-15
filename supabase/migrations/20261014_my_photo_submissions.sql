-- Issue #2 : "Mes soumissions" affichait les soumissions photo de tous les appareils.
-- Migration purement additive : une fonction SECURITY DEFINER + GRANT EXECUTE.
-- Aucune suppression, aucun ALTER de table, aucun REVOKE.
-- À appliquer dans Supabase AVANT de publier la version iOS qui appelle la RPC
-- (sans elle, l'app reçoit un 404 et affiche une liste vide).
-- Colonnes lues par l'app iOS (struct PhotoSubmission) : id, box_id, url, status,
-- submitted_at, review_notes ; filtre sur device_token (écrit par insertPhotoSubmission).
-- À vérifier avant exécution contre le schéma réel et contre pg_get_functiondef de
-- my_box_submissions (non lus par M0005 : aucun accès authentifié à la base).

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
stable
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

grant execute on function public.my_photo_submissions(text) to anon, authenticated;

-- Contrôle après application (appel anon, token bidon → []) :
--   curl -s "$SUPABASE_URL/rest/v1/rpc/my_photo_submissions" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
--     -H "Content-Type: application/json" -d '{"p_device_token":"bidon"}'
-- Lecture anon directe de la table (doit rester 401/403 ; constatée 401 le 2026-10-15) :
--   curl -s "$SUPABASE_URL/rest/v1/photo_submissions?select=id&limit=1" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
