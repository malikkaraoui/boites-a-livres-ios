-- Issue #6 : "Mes demandes de suppression" lisait la table deletion_requests avec la clé anon
-- (table lisible en entier, filtre device_token appliqué côté client).
-- Migration purement additive : une fonction SECURITY DEFINER + GRANT EXECUTE.
-- Aucune suppression, aucun ALTER de table, aucun REVOKE (le SELECT anon sur la table sera
-- retiré APRÈS publication des apps iOS et Android qui appellent la RPC).
-- Sans elle, l'app iOS reçoit un 404 PGRST202 et affiche une liste vide (rien ne casse).
-- Colonnes lues par l'app iOS (struct DeletionRequestRecord) : id, box_id, reason, status,
-- created_at ; filtre sur device_token (écrit par submitDeletionRequest).
-- Types DÉDUITS du modèle Swift (Int, Int, String, String, String horodaté) et du modèle
-- my_photo_submissions : à vérifier avant exécution contre le schéma réel
-- (\d public.deletion_requests) — non lu par M0007 : aucun accès authentifié à la base.
-- LIMIT 5 : même borne que l'ancienne lecture directe (order=created_at.desc&limit=5).

create or replace function public.my_deletion_requests(p_device_token text)
returns table (
  id bigint,
  box_id bigint,
  reason text,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select dr.id, dr.box_id, dr.reason, dr.status, dr.created_at
  from public.deletion_requests dr
  where p_device_token is not null
    and p_device_token <> ''
    and dr.device_token = p_device_token
  order by dr.created_at desc
  limit 5;
$$;

grant execute on function public.my_deletion_requests(text) to anon, authenticated;

-- Contrôle après application (appel anon, token bidon → []) :
--   curl -s "$SUPABASE_URL/rest/v1/rpc/my_deletion_requests" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
--     -H "Content-Type: application/json" -d '{"p_device_token":"bidon"}'
-- Lecture anon directe de la table (encore 200 tant que le REVOKE n'est pas fait) :
--   curl -s "$SUPABASE_URL/rest/v1/deletion_requests?select=id&limit=1" \
--     -H "apikey: $ANON" -H "Authorization: Bearer $ANON"
