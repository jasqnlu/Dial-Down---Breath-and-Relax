# Investigation: Apple accounts don't have their data saved after login

Date: 2026-09-19
Status: **Root cause found. No changes applied.** The proposed migration below needs approval before it touches the production database.
Supabase project: `wmsutfittuxrvcwuywrk`

## Symptom

After signing in with Apple, the account's data isn't saved.

## Root cause

**The Supabase tables can't be read or written by the app, for any sign-in method.** All five public tables (`exercises`, `profiles`, `push_tokens`, `routines`, `sessions`) have row-level-security policies, but the `anon` and `authenticated` roles have **no table privileges** on any of them. Postgres checks table privileges before RLS policies, so PostgREST answers every request with `403 permission denied` and the policies never run.

Nothing has ever been saved: `public.profiles` has zero rows even though the Apple and Google accounts both exist in `auth.users`.

## Evidence

1. **Auth users exist, no profile rows.** One Apple auth user and one Google auth user; `profiles` rows for either: 0.
2. **API logs (2026-09-19, ~21:15–21:21).** The app's profile lookup `GET /rest/v1/profiles?id=eq.<uid>&select=*&limit=1` returned **403** every time, for both the Apple and Google uids. `POST /rest/v1/profiles` returned 400 (see "Related findings").
3. **Privileges (`has_table_privilege`).** For every public table, `anon` and `authenticated` have `select`, `insert`, `update`, and `delete` all `false`. The role grants on `profiles` are only `REFERENCES, TRIGGER, TRUNCATE` for `anon`, `authenticated`, and `service_role`.
4. **The live `profiles` table doesn't match `supabase_schema.sql`.** It has only the public `SELECT` policy. The insert, update, and delete policies defined in the schema file are missing, so even with grants restored, writes would still be rejected.

## Why it looks Apple-specific

- Apple only returns the user's name the **first time** they authorize the app, and the app never stores it anywhere durable. The Apple auth user in Supabase has **no** `full_name`/`name` in its metadata.
- The Google auth user has `full_name` and `name`, and the Google name comes back from the provider on every login.
- With the profile lookup failing, Google logins are masked by that provider-supplied name. Apple has nothing to fall back on, so the missing data is visible there.

## Proposed fix (NOT applied)

A migration that grants each role exactly what the existing policies already assume, and restores the missing `profiles` write policies. Review the privacy question below before applying.

```sql
-- Table privileges the existing RLS policies already assume.
grant usage on schema public to anon, authenticated, service_role;

-- Public read-only catalog + leaderboard rows.
grant select on public.exercises to anon, authenticated;
grant select on public.profiles  to anon, authenticated;

-- Owners write their own rows (RLS restricts to auth.uid()).
grant insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.routines to anon, authenticated;
grant select, insert, update, delete on public.sessions to authenticated;
grant insert, update, delete on public.push_tokens to authenticated;

-- The streak-warning Edge Function uses the service role.
grant all on all tables in schema public to service_role;

-- Restore the profiles write policies that supabase_schema.sql defines
-- but the live database is missing.
create policy "users can insert their profile"
  on public.profiles for insert
  with check (auth.uid() is not null and id = auth.uid()::text);

create policy "users can update their profile"
  on public.profiles for update
  using (auth.uid() is not null and id = auth.uid()::text)
  with check (auth.uid() is not null and id = auth.uid()::text);

create policy "users can delete their profile"
  on public.profiles for delete
  using (auth.uid() is not null and id = auth.uid()::text);
```

Notes:
- `routines` needs `select` for `anon` because its policy allows anyone to read public routines. The other tables' write access is limited to `authenticated`, and RLS still scopes each row to its owner.
- An upsert (`INSERT ... ON CONFLICT DO UPDATE`) also needs `select`, which `authenticated` has on `profiles`.
- Put the same SQL in `supabase_schema.sql` in the same change so the file stays the source of truth.

## Open decision that affects this

`profiles` is publicly readable, and PR #26 makes `display_name` the full "First Last" name. Choose before applying: (a) accept public full names, (b) upload "First L." publicly, or (c) also keep `first_name`/`last_name` out of the public table. Granting `select` to `anon` on `profiles` makes whichever choice go live.

## Related findings

- **PR #26 depends on this.** Its name restore (name step, then a named `profiles` row) can't work until these grants and policies exist. It also still needs the separate `first_name`/`last_name` migration.
- **Two `POST /auth/v1/token?grant_type=id_token` requests returned 400** (2026-09-19 02:45 and 21:15). They are unexplained and don't account for the missing data. Worth a separate look at the Apple/Google token exchange.
- **Unit tests make real network calls to production.** The 401s at 16:37 came from `AuthManagerTests` signing out and deleting fake ids (`supabase-uid-123`) against the live project. Consider injecting a fake HTTP session.
- **Apple's name is never persisted.** Once the grants exist, the name step plus a `profiles` row is what restores it on later logins and new devices.
