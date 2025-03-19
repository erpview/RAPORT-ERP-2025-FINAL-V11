-- First drop existing policy if it exists
drop policy if exists "Allow admin reassign system ownership" on systems;

-- Add policy for admin to reassign system ownership with correct syntax
create policy "Allow admin reassign system ownership"
  on systems for update
  to authenticated
  using (
    -- Check if the user is an admin
    app_functions.is_admin(auth.uid())
  )
  with check (
    -- Verify admin status and that the new owner is an active editor
    app_functions.is_admin(auth.uid()) and exists (
      select 1
      from user_management
      where user_id = systems.created_by
      and role = 'editor'
      and is_active = true
    )
  );