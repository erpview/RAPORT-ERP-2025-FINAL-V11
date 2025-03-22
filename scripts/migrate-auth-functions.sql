-- Script to migrate custom functions from auth schema to app_functions schema
-- This will ensure compliance with the April 21 Supabase requirements

-- Create app_functions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS app_functions;

-- First, get the function definitions
SELECT pg_get_functiondef(p.oid) AS function_def
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'auth' AND p.proname = 'is_admin' AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = 'postgres');

SELECT pg_get_functiondef(p.oid) AS function_def
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'auth' AND p.proname = 'is_admin_by_metadata' AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = 'postgres');

SELECT pg_get_functiondef(p.oid) AS function_def
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'auth' AND p.proname = 'is_editor' AND p.proowner = (SELECT oid FROM pg_roles WHERE rolname = 'postgres');

-- Based on the function definitions, create the functions in app_functions schema
-- Note: You'll need to replace the placeholders below with the actual function definitions

-- Migrate is_admin function
CREATE OR REPLACE FUNCTION app_functions.is_admin(checking_user_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Replace this with the actual function body from the query above
  RETURN EXISTS (
    SELECT 1 
    FROM user_management 
    WHERE user_id = checking_user_id AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migrate is_admin_by_metadata function
CREATE OR REPLACE FUNCTION app_functions.is_admin_by_metadata()
RETURNS boolean AS $$
BEGIN
  -- Replace this with the actual function body from the query above
  RETURN EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_app_meta_data->>'role' in ('admin', 'service_role')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migrate is_editor function
CREATE OR REPLACE FUNCTION app_functions.is_editor(checking_user_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Replace this with the actual function body from the query above
  RETURN EXISTS (
    SELECT 1 
    FROM user_management 
    WHERE user_id = checking_user_id AND role = 'editor'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- After verifying that the new functions work correctly, drop the old ones
DROP FUNCTION IF EXISTS auth.is_admin(uuid);
DROP FUNCTION IF EXISTS auth.is_admin_by_metadata();
DROP FUNCTION IF EXISTS auth.is_editor(uuid);

-- Verify that the functions have been migrated successfully
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    r.rolname AS owner_name,
    pg_get_function_arguments(p.oid) AS function_arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_roles r ON p.proowner = r.oid
WHERE 
    n.nspname = 'app_functions' AND 
    p.proname IN ('is_admin', 'is_editor', 'is_admin_by_metadata');
