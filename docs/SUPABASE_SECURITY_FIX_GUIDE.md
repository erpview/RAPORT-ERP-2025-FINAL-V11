# Supabase Security Fix Guide: Exposed Auth Users

This guide provides step-by-step instructions for fixing the critical security vulnerability: "Exposed Auth Users" when a view/materialized view in the public schema exposes `auth.users` data to anon or authenticated roles.

## 🚨 Security Issue Overview

**Problem**: View/Materialized View exposes `auth.users` data to unauthorized roles
**Risk Level**: Critical
**Impact**: User data privacy breach, potential user enumeration attacks

## Step-by-Step Fix Process

### Step 1: Identify the Vulnerable View
```bash
# Search for the problematic view in your project
grep -r "user_emails_view" /path/to/project --exclude-dir=node_modules --exclude-dir=.git
```

### Step 2: Analyze the Security Vulnerability
Look for these patterns in your SQL files:
```sql
-- ❌ VULNERABLE PATTERN
CREATE OR REPLACE VIEW user_emails_view AS
SELECT 
    u.id,
    u.email,  -- Exposing auth.users data
    u.role
FROM auth.users u;

-- ❌ OVERLY PERMISSIVE ACCESS
GRANT SELECT ON user_emails_view TO authenticated;  -- All users can see all data
```

### Step 3: Create Secure Migration Script
Create a new migration file: `migrations/fix_user_emails_view_security.sql`

```sql
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
```

### Step 4: Update Application Code
Find and update any TypeScript/JavaScript code that uses the old view:

**Before (Vulnerable)**:
```typescript
const { data: userData, error: userError } = await supabase
    .from('user_emails_view')
    .select('id, email')
    .in('id', userIds);
```

**After (Secure)**:
```typescript
const { data: userData, error: userError } = await supabase
    .rpc('get_user_emails_for_reports', {
        report_user_ids: userIds
    });
```

### Step 5: Execute Migration in Supabase
1. Open Supabase Dashboard → SQL Editor
2. Paste the migration script
3. **Expected Warning**: "Query has destructive operation" - This is normal for DROP VIEW
4. **Confirm execution** - The DROP is intentional and safe
5. **Expected Result**: "Success. No rows returned" - This is correct

### Step 6: Test the Fix
1. **Test authorized access**: Admin/editor users should still be able to view reports
2. **Test unauthorized access**: Regular users should not be able to access user emails
3. **Verify functionality**: Comparison reports should work normally for authorized users

### Step 7: Commit and Push Changes
```bash
git add .
git commit -m "Fix critical security vulnerability: user_emails_view exposing auth.users data

- Remove insecure user_emails_view that granted SELECT access to all authenticated users
- Create secure get_user_emails_for_reports() function with role-based access control
- Function only accessible by admins/editors and returns only requested user IDs
- Update application code to use secure RPC function instead of direct view access
- Resolves Supabase security warning about exposed auth.users data"

git push origin main
```

## Security Best Practices

### ✅ Do's
- **Use functions with SECURITY DEFINER** for controlled access
- **Implement role-based access control** in functions
- **Return only necessary data** (parameter-based filtering)
- **Use proper error handling** for unauthorized access
- **Grant minimal permissions** (principle of least privilege)

### ❌ Don'ts
- **Never grant broad SELECT access** to views containing auth.users
- **Avoid exposing auth schema data** directly to public schema
- **Don't use views for sensitive data** without proper RLS
- **Never ignore Supabase security warnings**

## Common Vulnerable Patterns to Avoid

```sql
-- ❌ DANGEROUS: Exposes all user data
CREATE VIEW public.all_users AS SELECT * FROM auth.users;
GRANT SELECT ON all_users TO authenticated;

-- ❌ DANGEROUS: No access control
CREATE VIEW public.user_info AS 
SELECT id, email, role FROM auth.users;
GRANT SELECT ON user_info TO anon, authenticated;

-- ✅ SECURE: Function with proper access control
CREATE FUNCTION public.get_user_info(user_ids UUID[])
RETURNS TABLE(id UUID, email TEXT)
SECURITY DEFINER
AS $$ 
BEGIN
    -- Check permissions first
    IF NOT has_admin_role() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;
    
    RETURN QUERY SELECT u.id, u.email 
    FROM auth.users u 
    WHERE u.id = ANY(user_ids);
END;
$$;
```

## Verification Checklist

- [ ] Vulnerable view/materialized view removed
- [ ] Secure function created with proper access control
- [ ] Application code updated to use secure function
- [ ] Migration executed successfully in Supabase
- [ ] Functionality tested for authorized users
- [ ] Unauthorized access properly blocked
- [ ] Changes committed and pushed to repository
- [ ] Supabase security warning resolved

This approach ensures user data privacy while maintaining necessary functionality for authorized operations.
