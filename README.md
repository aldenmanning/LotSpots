# LotSpots Supabase Frontend

React/Vite frontend for a LotSpots marketplace dashboard backed by Supabase.

## Local setup

```bash
npm install
cp .env.example .env.local
npm run dev
```

Add these Vercel environment variables before using live Supabase data:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

The app includes mock data fallback so it will still render before Supabase is connected.
