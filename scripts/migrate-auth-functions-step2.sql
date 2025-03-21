-- Script to migrate custom functions from auth schema to app_functions schema (Step 2)
-- ONLY RUN THIS AFTER THOROUGHLY TESTING THAT THE NEW FUNCTIONS WORK CORRECTLY
-- This script contains destructive operations that will remove the old functions

-- Verify that the new functions exist before proceeding
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'app_functions' AND p.proname = 'is_admin'
  ) THEN
    RAISE EXCEPTION 'app_functions.is_admin function does not exist. Run Step 1 first.';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'app_functions' AND p.proname = 'is_admin_by_metadata'
  ) THEN
    RAISE EXCEPTION 'app_functions.is_admin_by_metadata function does not exist. Run Step 1 first.';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'app_functions' AND p.proname = 'is_editor'
  ) THEN
    RAISE EXCEPTION 'app_functions.is_editor function does not exist. Run Step 1 first.';
  END IF;
END $$;

-- After verifying that the new functions exist and work correctly, drop the old ones
DROP FUNCTION IF EXISTS auth.is_admin(uuid);
DROP FUNCTION IF EXISTS auth.is_admin_by_metadata();
DROP FUNCTION IF EXISTS auth.is_editor(uuid);

-- Verify that the old functions have been removed
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE 
    n.nspname = 'auth' AND 
    p.proname IN ('is_admin', 'is_editor', 'is_admin_by_metadata') AND
    p.proowner = (SELECT oid FROM pg_roles WHERE rolname = 'postgres');

-- The query above should return no rows if all functions were successfully removed
