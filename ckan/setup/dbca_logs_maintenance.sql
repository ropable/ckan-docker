DELETE FROM "public"."dbca_logs"
WHERE to_timestamp("timestamp", 'YYYY-MM-DD HH24:MI:SS,MS') < NOW() - INTERVAL '30 days'
;
VACUUM "public"."dbca_logs"
;