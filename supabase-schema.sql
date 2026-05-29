create extension if not exists "pgcrypto";

create table if not exists owners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  entity_name text,
  email text,
  phone text,
  verification_status text default 'not_started',
  payment_status text default 'not_started',
  tax_status text default 'not_started',
  created_at timestamptz default now()
);

create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references owners(id) on delete set null,
  name text not null,
  address text not null,
  city text,
  state text,
  zip text,
  parcel_number text,
  latitude numeric,
  longitude numeric,
  property_type text,
  zoning text,
  historic_district boolean default false,
  municipality text,
  county text,
  traffic_estimate integer,
  verification_status text default 'unverified',
  compliance_status text default 'manual_review_needed',
  created_at timestamptz default now()
);

create table if not exists placements (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  name text not null,
  placement_type text,
  dimensions text,
  facing_direction text,
  facing_street text,
  traffic_estimate integer,
  visibility_score integer default 0,
  allowed_formats text[],
  blocked_categories text[],
  installation_method text,
  access_instructions text,
  estimated_monthly_low integer,
  estimated_monthly_high integer,
  status text default 'draft',
  created_at timestamptz default now()
);

create table if not exists advertisers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  contact_name text,
  email text,
  phone text,
  created_at timestamptz default now()
);

create table if not exists creatives (
  id uuid primary key default gen_random_uuid(),
  advertiser_id uuid references advertisers(id) on delete cascade,
  name text not null,
  copy text,
  image_url text,
  status text default 'draft',
  sensitive_flags text[],
  created_at timestamptz default now()
);

create table if not exists campaigns (
  id uuid primary key default gen_random_uuid(),
  advertiser_id uuid references advertisers(id) on delete set null,
  placement_id uuid references placements(id) on delete set null,
  creative_id uuid references creatives(id) on delete set null,
  title text not null,
  start_date date,
  end_date date,
  gross_price integer,
  owner_payout integer,
  lotspots_fee integer,
  status text default 'requested',
  compliance_status text default 'manual_review_needed',
  installation_status text default 'not_scheduled',
  created_at timestamptz default now()
);

create table if not exists permits (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete cascade,
  status text default 'not_started',
  permit_type text,
  responsible_party text,
  expiration_date date,
  notes text,
  created_at timestamptz default now()
);

create table if not exists installations (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  installer_name text,
  scheduled_at timestamptz,
  method text,
  status text default 'not_scheduled',
  before_photo_url text,
  after_photo_url text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists incidents (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  type text,
  severity text default 'normal',
  status text default 'reported',
  description text,
  photo_url text,
  created_at timestamptz default now()
);

create table if not exists payouts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references owners(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  gross_amount integer,
  fees integer,
  net_payout integer,
  status text default 'scheduled',
  payment_date date,
  tax_year integer,
  created_at timestamptz default now()
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  campaign_id uuid references campaigns(id) on delete set null,
  document_type text,
  title text not null,
  file_url text,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  campaign_id uuid references campaigns(id) on delete set null,
  category text,
  subject text,
  body text,
  status text default 'open',
  created_at timestamptz default now()
);

alter table owners enable row level security;
alter table properties enable row level security;
alter table placements enable row level security;
alter table advertisers enable row level security;
alter table creatives enable row level security;
alter table campaigns enable row level security;
alter table permits enable row level security;
alter table installations enable row level security;
alter table incidents enable row level security;
alter table payouts enable row level security;
alter table documents enable row level security;
alter table messages enable row level security;
