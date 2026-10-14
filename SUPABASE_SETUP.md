# Supabase setup

1. Create a Supabase project and enable Email authentication in Authentication > Providers.
2. Run `supabase/migrations/20260922000000_create_profiles.sql` in the SQL editor. It creates a profile when a user signs up, backfills existing accounts, and allows users to read only their own profile.
3. Under Authentication > URL Configuration, add `io.seren.meditation://auth-callback` to Redirect URLs. This is used for confirmation and password reset emails.
4. Create a local `.env.json` (ignored by Git):

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_KEY"
}
```

5. Run `flutter run --dart-define-from-file=.env.json`. Use the same define file for release builds.

Only the **publishable** key belongs in the app. Never put the secret or service-role key in a client build. Supabase persists the signed-in session locally; after the five-second Seren intro, returning users land on Home. Sign-out returns to authentication. With email confirmation enabled, new users must open the email link before they can sign in.
