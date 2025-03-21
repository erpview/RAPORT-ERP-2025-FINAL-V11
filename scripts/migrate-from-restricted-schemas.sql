-- Script to migrate objects from restricted Supabase schemas
-- This script will help you move tables and functions from auth, storage, and realtime schemas
-- to comply with the April 21 Supabase requirements

-- Create app_functions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS app_functions;

-- Part 1: Identify custom tables in restricted schemas
WITH custom_tables AS (
    SELECT 
        n.nspname AS schema_name,
        c.relname AS table_name,
        r.rolname AS owner_name
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_roles r ON c.relowner = r.oid
    WHERE 
        c.relkind = 'r' AND -- Only regular tables
        (
            (n.nspname = 'auth' AND r.rolname != 'supabase_auth_admin')
            OR (n.nspname = 'storage' AND r.rolname != 'supabase_storage_admin')
            OR (
                n.nspname = 'realtime'
                AND r.rolname NOT IN ('supabase_admin', 'supabase_realtime_admin')
            )
        )
)
SELECT 
    'ALTER TABLE ' || schema_name || '.' || table_name || ' SET SCHEMA app_functions;' AS migration_command
FROM custom_tables;

-- Part 2: Identify custom functions in restricted schemas
WITH custom_functions AS (
    SELECT 
        n.nspname AS schema_name,
        p.proname AS function_name,
        r.rolname AS owner_name,
        p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    JOIN pg_roles r ON p.proowner = r.oid
    WHERE 
        (n.nspname = 'auth' AND r.rolname != 'supabase_auth_admin')
        OR (n.nspname = 'storage' AND r.rolname != 'supabase_storage_admin')
        OR (
            n.nspname = 'realtime'
            AND r.rolname NOT IN ('supabase_admin', 'supabase_realtime_admin')
        )
)
SELECT 
    'ALTER FUNCTION ' || schema_name || '.' || function_name || 
    '(' || pg_get_function_arguments(oid) || ') SET SCHEMA app_functions;' AS migration_command
FROM custom_functions;

-- Part 3: Check for any remaining functions in auth schema after migration
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    r.rolname AS owner_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_roles r ON p.proowner = r.oid
WHERE 
    n.nspname = 'auth' AND 
    p.proname IN ('is_admin', 'is_editor', 'is_admin_by_metadata') AND
    r.rolname != 'supabase_auth_admin';

-- Part 4: Generate statements to update any remaining references in policies
WITH policies AS (
    SELECT
        schemaname,
        tablename,
        policyname,
        cmd,
        qual,
        with_check,
        pg_get_expr(p.polqual, p.polrelid) AS using_expr,
        pg_get_expr(p.polwithcheck, p.polrelid) AS with_check_expr
    FROM
        pg_policies pol
    JOIN pg_policy p ON pol.policyname = p.polname
    JOIN pg_class c ON p.polrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = pol.schemaname AND c.relname = pol.tablename
),
policy_updates AS (
    SELECT
        'DROP POLICY IF EXISTS ' || quote_ident(policyname) || ' ON ' || 
        quote_ident(schemaname) || '.' || quote_ident(tablename) || ';' AS drop_stmt,
        
        CASE
            WHEN cmd = 'SELECT' OR cmd = 'DELETE' THEN
                'CREATE POLICY ' || quote_ident(policyname) || ' ON ' || 
                quote_ident(schemaname) || '.' || quote_ident(tablename) || 
                ' FOR ' || cmd || ' TO authenticated USING (' || 
                replace(replace(using_expr, 'auth.is_admin', 'app_functions.is_admin'), 
                       'auth.is_editor', 'app_functions.is_editor') || ');'
                
            WHEN cmd = 'INSERT' THEN
                'CREATE POLICY ' || quote_ident(policyname) || ' ON ' || 
                quote_ident(schemaname) || '.' || quote_ident(tablename) || 
                ' FOR ' || cmd || ' TO authenticated WITH CHECK (' || 
                replace(replace(COALESCE(with_check_expr, using_expr), 'auth.is_admin', 'app_functions.is_admin'), 
                       'auth.is_editor', 'app_functions.is_editor') || ');'
                
            WHEN cmd = 'UPDATE' THEN
                'CREATE POLICY ' || quote_ident(policyname) || ' ON ' || 
                quote_ident(schemaname) || '.' || quote_ident(tablename) || 
                ' FOR ' || cmd || ' TO authenticated USING (' || 
                replace(replace(using_expr, 'auth.is_admin', 'app_functions.is_admin'), 
                       'auth.is_editor', 'app_functions.is_editor') || 
                CASE WHEN with_check_expr IS NOT NULL 
                    THEN ') WITH CHECK (' || 
                         replace(replace(with_check_expr, 'auth.is_admin', 'app_functions.is_admin'), 
                                'auth.is_editor', 'app_functions.is_editor') 
                    ELSE '' 
                END || ');'
                
            WHEN cmd = 'ALL' THEN
                'CREATE POLICY ' || quote_ident(policyname) || ' ON ' || 
                quote_ident(schemaname) || '.' || quote_ident(tablename) || 
                ' FOR ALL TO authenticated USING (' || 
                replace(replace(using_expr, 'auth.is_admin', 'app_functions.is_admin'), 
                       'auth.is_editor', 'app_functions.is_editor') || 
                CASE WHEN with_check_expr IS NOT NULL 
                    THEN ') WITH CHECK (' || 
                         replace(replace(with_check_expr, 'auth.is_admin', 'app_functions.is_admin'), 
                                'auth.is_editor', 'app_functions.is_editor') 
                    ELSE '' 
                END || ');'
        END AS create_stmt
    FROM
        policies
    WHERE
        using_expr LIKE '%auth.is_%' OR with_check_expr LIKE '%auth.is_%'
)
SELECT drop_stmt, create_stmt FROM policy_updates;
