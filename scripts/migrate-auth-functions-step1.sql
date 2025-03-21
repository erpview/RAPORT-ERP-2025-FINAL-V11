-- Script to migrate custom functions from auth schema to app_functions schema (Step 1)
-- This will ensure compliance with the April 21 Supabase requirements
-- SAFE VERSION - NO DESTRUCTIVE OPERATIONS

-- Create app_functions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS app_functions;

-- Migrate is_admin function
CREATE OR REPLACE FUNCTION app_functions.is_admin(checking_user_id uuid)
RETURNS boolean AS $$
BEGIN
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
  RETURN EXISTS (
    SELECT 1 
    FROM user_management 
    WHERE user_id = checking_user_id AND role = 'editor'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify that the functions have been created successfully
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
