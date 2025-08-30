-- Fix critical security issue: user_emails_view exposing auth.users data
-- This migration secures the view with proper Row Level Security

-- Drop the insecure view
DROP VIEW IF EXISTS public.user_emails_view;

-- Create a secure function instead of a view
-- This function will only return user data that the current user is authorized to see
CREATE OR REPLACE FUNCTION public.get_user_emails_for_reports(report_user_ids UUID[])
RETURNS TABLE (
    id UUID,
    email TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only allow admins and editors to call this function
    IF NOT EXISTS (
        SELECT 1 
        FROM user_management 
        WHERE user_management.id = auth.uid() 
        AND user_management.role IN ('editor', 'admin')
    ) THEN
        RAISE EXCEPTION 'Access denied: Only admins and editors can access user emails';
    END IF;

    -- Return only the requested user IDs (for comparison reports)
    RETURN QUERY
    SELECT 
        u.id,
        COALESCE(um.email, u.email) AS email
    FROM auth.users u
    LEFT JOIN user_management um ON um.id = u.id
    WHERE u.id = ANY(report_user_ids);
END;
$$;

-- Grant execute permission only to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_emails_for_reports(UUID[]) TO authenticated;

-- Add comment explaining the security fix
COMMENT ON FUNCTION public.get_user_emails_for_reports IS 
'Secure function to get user emails for comparison reports. Only accessible by admins/editors and only returns requested user IDs.';
