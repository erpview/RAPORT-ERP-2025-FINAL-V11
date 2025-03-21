-- Script to check if your project meets the new Supabase requirements
-- Run this script to identify any custom tables or functions in restricted schemas

-- Check if you created any tables in the auth, storage, and realtime schemas
SELECT 
    n.nspname AS schema_name,
    c.relname AS table_name,
    r.rolname AS owner_name,
    c.relkind AS object_type
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_roles r ON c.relowner = r.oid
WHERE 
    (n.nspname = 'auth' AND r.rolname != 'supabase_auth_admin')
    OR (n.nspname = 'storage' AND r.rolname != 'supabase_storage_admin')
    OR (
        n.nspname = 'realtime'
        AND r.rolname NOT IN ('supabase_admin', 'supabase_realtime_admin')
    );

-- Check if you created any database functions in the auth, storage, and realtime schemas
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    r.rolname AS owner_name,
    pg_get_function_arguments(p.oid) AS function_arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_roles r ON p.proowner = r.oid
WHERE 
    (n.nspname = 'auth' AND r.rolname != 'supabase_auth_admin')
    OR (n.nspname = 'storage' AND r.rolname != 'supabase_storage_admin')
    OR (
        n.nspname = 'realtime'
        AND r.rolname NOT IN ('supabase_admin', 'supabase_realtime_admin')
    );

-- List all functions in the auth schema for reference
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    r.rolname AS owner_name,
    pg_get_function_arguments(p.oid) AS function_arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_roles r ON p.proowner = r.oid
WHERE n.nspname = 'auth'
ORDER BY p.proname;
