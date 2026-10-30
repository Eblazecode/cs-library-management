# NEXTLIB — Computer Science Library

This is a **reconstructed starter source package** based on the deployed NEXTLIB project structure and visible application concepts. It is not guaranteed to be byte-for-byte identical to the original deployment source.

## Requirements
- Node.js 20+
- npm
- Supabase project (optional for preview; required for persistent storage)

## Run locally
```bash
npm install
cp .env.example .env.local
npm run dev
```
Add your Supabase project URL and publishable key to `.env.local`.

## Supabase setup
1. Open your Supabase project.
2. Go to SQL Editor.
3. Review and run `supabase/schema.sql`.
4. Configure Supabase Authentication and staff access policies before production.
5. Restart the dev server.

The UI displays demo catalogue records when Supabase is not configured. In that mode, newly added records exist only in the current browser session and are not persistent. With Supabase configured, the catalogue loads from `public.books` and new books are inserted into that table.

## Deploy
Push the project to your GitHub repository and import it in Vercel. Add:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

Do not put service-role keys or other secrets in `NEXT_PUBLIC_*` variables. The starter only integrates book catalogue read/insert; member management, circulation workflows, audit logs, and role-based admin features still require implementation and testing.
