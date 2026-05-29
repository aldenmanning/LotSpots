-- LotSpots Supabase Schema v2
-- Future-proof, non-destructive schema for parcels, properties, placements, campaigns, compliance, execution, payouts, agents, and audit trails.

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
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  phone text,
  avatar_url text,
  default_role text check (default_role in ('host','advertiser','agent','admin')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  organization_type text check (organization_type in ('host_entity','advertiser','agency','installer','vendor','lotspots')),
  website text,
  phone text,
  email text,
  billing_email text,
  tax_status text default 'not_started',
  verification_status text default 'not_started',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  user_id uuid references users(id) on delete cascade,
  role text not null,
  can_approve_campaigns boolean default false,
  can_manage_payouts boolean default false,
  can_manage_documents boolean default false,
  can_manage_properties boolean default false,
  created_at timestamptz default now(),
  unique (organization_id, user_id)
);

create table if not exists parcel_profiles (
  id uuid primary key default gen_random_uuid(),
  source_county text,
  source_state text,
  source_parcel_id text,
  parcel_number text,
  normalized_address text,
  street_address text,
  city text,
  state text,
  zip text,
  county text,
  municipality text,
  owner_name text,
  owner_mailing_address text,
  legal_owner_entity text,
  land_use_code text,
  property_class text,
  acreage numeric,
  assessed_land_value numeric,
  assessed_building_value numeric,
  assessed_total_value numeric,
  tax_district text,
  zoning text,
  historic_district boolean,
  overlay_districts text[],
  latitude numeric,
  longitude numeric,
  boundary_geojson jsonb,
  data_confidence numeric,
  source_url text,
  source_last_checked_at timestamptz,
  source_updated_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (source_state, source_county, source_parcel_id)
);

create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references owners(id) on delete set null,
  parcel_profile_id uuid references parcel_profiles(id) on delete set null,
  host_organization_id uuid references organizations(id) on delete set null,
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
  marketplace_status text default 'potential',
  verification_status text default 'unverified',
  compliance_status text default 'manual_review_needed',
  owner_claim_status text default 'unclaimed',
  public_listing_enabled boolean default false,
  internal_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table properties add column if not exists parcel_profile_id uuid references parcel_profiles(id) on delete set null;
alter table properties add column if not exists host_organization_id uuid references organizations(id) on delete set null;
alter table properties add column if not exists marketplace_status text default 'potential';
alter table properties add column if not exists owner_claim_status text default 'unclaimed';
alter table properties add column if not exists public_listing_enabled boolean default false;
alter table properties add column if not exists internal_notes text;
alter table properties add column if not exists updated_at timestamptz default now();

create table if not exists property_claims (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  claimant_user_id uuid references users(id) on delete set null,
  claimant_organization_id uuid references organizations(id) on delete set null,
  claim_type text check (claim_type in ('owner','manager','tenant','agent','authorized_representative')),
  status text default 'submitted',
  evidence_document_id uuid,
  reviewed_by uuid references users(id) on delete set null,
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz default now()
);

create table if not exists file_assets (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references users(id) on delete set null,
  organization_id uuid references organizations(id) on delete set null,
  bucket text,
  path text,
  public_url text,
  mime_type text,
  size_bytes bigint,
  title text,
  description text,
  metadata jsonb,
  created_at timestamptz default now()
);

create table if not exists placements (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  name text not null,
  placement_type text,
  description text,
  exact_location text,
  dimensions text,
  width_feet numeric,
  height_feet numeric,
  area_sqft numeric,
  facing_direction text,
  facing_street text,
  latitude numeric,
  longitude numeric,
  photo_url text,
  map_pin jsonb,
  traffic_estimate integer,
  visibility_score numeric default 0,
  allowed_formats text[],
  blocked_categories text[],
  manual_approval_required boolean default true,
  installation_method text,
  access_instructions text,
  min_booking_days integer,
  max_booking_days integer,
  estimated_monthly_low integer,
  estimated_monthly_high integer,
  status text default 'draft',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table placements add column if not exists description text;
alter table placements add column if not exists exact_location text;
alter table placements add column if not exists width_feet numeric;
alter table placements add column if not exists height_feet numeric;
alter table placements add column if not exists area_sqft numeric;
alter table placements add column if not exists latitude numeric;
alter table placements add column if not exists longitude numeric;
alter table placements add column if not exists photo_url text;
alter table placements add column if not exists map_pin jsonb;
alter table placements add column if not exists manual_approval_required boolean default true;
alter table placements add column if not exists min_booking_days integer;
alter table placements add column if not exists max_booking_days integer;
alter table placements add column if not exists updated_at timestamptz default now();

create table if not exists placement_rules (
  id uuid primary key default gen_random_uuid(),
  placement_id uuid references placements(id) on delete cascade,
  rule_type text not null,
  rule_value jsonb not null,
  created_at timestamptz default now()
);

create table if not exists placement_availability (
  id uuid primary key default gen_random_uuid(),
  placement_id uuid references placements(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  availability_type text check (availability_type in ('available','blocked','pending','booked','maintenance','permit_hold')),
  reason text,
  created_at timestamptz default now()
);

create table if not exists valuation_runs (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete cascade,
  model_version text,
  estimated_daily_value numeric,
  estimated_monthly_low numeric,
  estimated_monthly_base numeric,
  estimated_monthly_high numeric,
  estimated_event_value numeric,
  traffic_count integer,
  visibility_score numeric,
  demand_score numeric,
  compliance_risk_score numeric,
  local_market_factor numeric,
  estimated_cpm numeric,
  confidence_score numeric,
  inputs jsonb,
  explanation text,
  created_at timestamptz default now()
);

create table if not exists traffic_counts (
  id uuid primary key default gen_random_uuid(),
  source text,
  station_id text,
  route text,
  road_name text,
  location_description text,
  year integer,
  aadt integer,
  latitude numeric,
  longitude numeric,
  geometry_geojson jsonb,
  source_url text,
  source_last_checked_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists zoning_records (
  id uuid primary key default gen_random_uuid(),
  parcel_profile_id uuid references parcel_profiles(id) on delete cascade,
  property_id uuid references properties(id) on delete cascade,
  jurisdiction text,
  zoning_code text,
  zoning_description text,
  overlay_districts text[],
  historic_district boolean,
  sign_rules_summary text,
  source_url text,
  confidence_score numeric,
  reviewed_status text default 'unreviewed',
  last_checked_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists compliance_reviews (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete cascade,
  campaign_id uuid,
  review_type text check (review_type in ('zoning','sign_code','historic','dot','permit','content','safety','manual')),
  status text default 'manual_review_needed',
  risk_level text default 'unknown',
  summary text,
  required_actions jsonb,
  reviewed_by uuid references users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists advertisers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete set null,
  name text not null,
  category text,
  industry text,
  website text,
  contact_name text,
  email text,
  phone text,
  verification_status text default 'unverified',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table advertisers add column if not exists organization_id uuid references organizations(id) on delete set null;
alter table advertisers add column if not exists industry text;
alter table advertisers add column if not exists website text;
alter table advertisers add column if not exists verification_status text default 'unverified';
alter table advertisers add column if not exists updated_at timestamptz default now();

create table if not exists campaigns (
  id uuid primary key default gen_random_uuid(),
  advertiser_id uuid references advertisers(id) on delete set null,
  placement_id uuid references placements(id) on delete set null,
  creative_id uuid,
  title text not null,
  campaign_type text,
  start_date date,
  end_date date,
  gross_price integer,
  owner_payout integer,
  lotspots_fee integer,
  total_budget numeric,
  status text default 'draft',
  compliance_status text default 'manual_review_needed',
  creative_status text default 'not_submitted',
  payment_status text default 'not_started',
  installation_status text default 'not_scheduled',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table campaigns add column if not exists campaign_type text;
alter table campaigns add column if not exists total_budget numeric;
alter table campaigns add column if not exists creative_status text default 'not_submitted';
alter table campaigns add column if not exists payment_status text default 'not_started';
alter table campaigns add column if not exists updated_at timestamptz default now();

create table if not exists campaign_placements (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  placement_id uuid references placements(id) on delete set null,
  start_date date,
  end_date date,
  gross_price numeric,
  owner_payout numeric,
  lotspots_fee numeric,
  agent_fee numeric,
  installer_fee numeric,
  permit_fee numeric,
  status text default 'requested',
  approval_status text default 'pending',
  installation_status text default 'not_scheduled',
  created_at timestamptz default now()
);

create table if not exists creatives (
  id uuid primary key default gen_random_uuid(),
  advertiser_id uuid references advertisers(id) on delete cascade,
  campaign_id uuid references campaigns(id) on delete cascade,
  name text not null,
  headline text,
  body_copy text,
  copy text,
  call_to_action text,
  destination_url text,
  image_url text,
  file_asset_id uuid references file_assets(id) on delete set null,
  format text,
  sensitive_flags text[],
  status text default 'draft',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table creatives add column if not exists campaign_id uuid references campaigns(id) on delete cascade;
alter table creatives add column if not exists headline text;
alter table creatives add column if not exists body_copy text;
alter table creatives add column if not exists call_to_action text;
alter table creatives add column if not exists destination_url text;
alter table creatives add column if not exists file_asset_id uuid references file_assets(id) on delete set null;
alter table creatives add column if not exists format text;
alter table creatives add column if not exists updated_at timestamptz default now();

create table if not exists creative_reviews (
  id uuid primary key default gen_random_uuid(),
  creative_id uuid references creatives(id) on delete cascade,
  placement_id uuid references placements(id) on delete cascade,
  reviewer_user_id uuid references users(id) on delete set null,
  reviewer_organization_id uuid references organizations(id) on delete set null,
  decision text check (decision in ('pending','approved','rejected','changes_requested')),
  notes text,
  decided_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists permits (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete cascade,
  campaign_id uuid references campaigns(id) on delete set null,
  jurisdiction text,
  permit_type text,
  status text default 'not_started',
  responsible_party text,
  application_url text,
  permit_number text,
  submitted_at timestamptz,
  approved_at timestamptz,
  expiration_date date,
  document_id uuid,
  notes text,
  created_at timestamptz default now()
);

alter table permits add column if not exists campaign_id uuid references campaigns(id) on delete set null;
alter table permits add column if not exists jurisdiction text;
alter table permits add column if not exists application_url text;
alter table permits add column if not exists permit_number text;
alter table permits add column if not exists submitted_at timestamptz;
alter table permits add column if not exists approved_at timestamptz;
alter table permits add column if not exists document_id uuid;

create table if not exists installations (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id) on delete cascade,
  campaign_placement_id uuid references campaign_placements(id) on delete cascade,
  installer_name text,
  installer_organization_id uuid references organizations(id) on delete set null,
  scheduled_at timestamptz,
  scheduled_start_at timestamptz,
  scheduled_end_at timestamptz,
  method text,
  access_notes text,
  electrical_required boolean default false,
  surface_attachment_details text,
  status text default 'not_scheduled',
  before_photo_url text,
  after_photo_url text,
  before_photo_asset_id uuid references file_assets(id) on delete set null,
  after_photo_asset_id uuid references file_assets(id) on delete set null,
  owner_signoff_status text default 'not_requested',
  notes text,
  created_at timestamptz default now()
);

alter table installations add column if not exists campaign_placement_id uuid references campaign_placements(id) on delete cascade;
alter table installations add column if not exists installer_organization_id uuid references organizations(id) on delete set null;
alter table installations add column if not exists scheduled_start_at timestamptz;
alter table installations add column if not exists scheduled_end_at timestamptz;
alter table installations add column if not exists access_notes text;
alter table installations add column if not exists electrical_required boolean default false;
alter table installations add column if not exists surface_attachment_details text;
alter table installations add column if not exists before_photo_asset_id uuid references file_assets(id) on delete set null;
alter table installations add column if not exists after_photo_asset_id uuid references file_assets(id) on delete set null;
alter table installations add column if not exists owner_signoff_status text default 'not_requested';

create table if not exists inspections (
  id uuid primary key default gen_random_uuid(),
  campaign_placement_id uuid references campaign_placements(id) on delete cascade,
  installation_id uuid references installations(id) on delete set null,
  inspection_type text check (inspection_type in ('install','active','maintenance','removal','proof_of_display')),
  status text default 'pending',
  inspected_by uuid references users(id) on delete set null,
  inspected_at timestamptz,
  latitude numeric,
  longitude numeric,
  photo_asset_ids uuid[],
  notes text,
  created_at timestamptz default now()
);

create table if not exists proof_of_display (
  id uuid primary key default gen_random_uuid(),
  campaign_placement_id uuid references campaign_placements(id) on delete cascade,
  inspection_id uuid references inspections(id) on delete set null,
  proof_type text,
  photo_asset_id uuid references file_assets(id) on delete set null,
  captured_at timestamptz,
  latitude numeric,
  longitude numeric,
  verified_status text default 'pending',
  notes text,
  created_at timestamptz default now()
);

create table if not exists incidents (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  installation_id uuid references installations(id) on delete set null,
  incident_type text,
  type text,
  severity text default 'normal',
  status text default 'reported',
  description text,
  responsible_party text,
  estimated_resolution_date date,
  payment_adjustment numeric,
  photo_url text,
  photo_asset_ids uuid[],
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table incidents add column if not exists installation_id uuid references installations(id) on delete set null;
alter table incidents add column if not exists incident_type text;
alter table incidents add column if not exists responsible_party text;
alter table incidents add column if not exists estimated_resolution_date date;
alter table incidents add column if not exists payment_adjustment numeric;
alter table incidents add column if not exists photo_asset_ids uuid[];
alter table incidents add column if not exists updated_at timestamptz default now();

create table if not exists payouts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references owners(id) on delete set null,
  recipient_organization_id uuid references organizations(id) on delete set null,
  recipient_user_id uuid references users(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  gross_amount numeric,
  fees numeric,
  fee_amount numeric,
  net_payout numeric,
  net_amount numeric,
  status text default 'scheduled',
  payment_date date,
  tax_year integer,
  statement_document_id uuid,
  created_at timestamptz default now()
);

alter table payouts add column if not exists recipient_organization_id uuid references organizations(id) on delete set null;
alter table payouts add column if not exists recipient_user_id uuid references users(id) on delete set null;
alter table payouts add column if not exists fee_amount numeric;
alter table payouts add column if not exists net_amount numeric;
alter table payouts add column if not exists statement_document_id uuid;

create table if not exists payout_line_items (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid references payouts(id) on delete cascade,
  campaign_placement_id uuid references campaign_placements(id) on delete set null,
  line_type text,
  description text,
  amount numeric not null,
  created_at timestamptz default now()
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete set null,
  property_id uuid references properties(id) on delete set null,
  placement_id uuid references placements(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  document_type text,
  title text not null,
  file_url text,
  status text default 'active',
  signed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz default now()
);

alter table documents add column if not exists organization_id uuid references organizations(id) on delete set null;
alter table documents add column if not exists placement_id uuid references placements(id) on delete set null;
alter table documents add column if not exists signed_at timestamptz;
alter table documents add column if not exists expires_at timestamptz;

create table if not exists message_threads (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete set null,
  campaign_id uuid references campaigns(id) on delete set null,
  subject text,
  status text default 'open',
  created_at timestamptz default now()
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid references message_threads(id) on delete cascade,
  property_id uuid references properties(id) on delete cascade,
  campaign_id uuid references campaigns(id) on delete set null,
  sender_user_id uuid references users(id) on delete set null,
  category text,
  subject text,
  body text,
  status text default 'open',
  created_at timestamptz default now()
);

alter table messages add column if not exists thread_id uuid references message_threads(id) on delete cascade;
alter table messages add column if not exists sender_user_id uuid references users(id) on delete set null;

create table if not exists agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  organization_id uuid references organizations(id) on delete set null,
  certification_status text default 'not_started',
  commission_rate numeric,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists agent_assignments (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agents(id) on delete cascade,
  property_id uuid references properties(id) on delete cascade,
  placement_id uuid references placements(id) on delete set null,
  assignment_type text check (assignment_type in ('sourcing','owner_outreach','sales','campaign_management','compliance')),
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references users(id) on delete set null,
  actor_organization_id uuid references organizations(id) on delete set null,
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  previous_value jsonb,
  new_value jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_properties_parcel_profile_id on properties(parcel_profile_id);
create index if not exists idx_properties_host_organization_id on properties(host_organization_id);
create index if not exists idx_properties_marketplace_status on properties(marketplace_status);
create index if not exists idx_placements_property_id on placements(property_id);
create index if not exists idx_campaigns_advertiser_id on campaigns(advertiser_id);
create index if not exists idx_campaign_placements_campaign_id on campaign_placements(campaign_id);
create index if not exists idx_campaign_placements_placement_id on campaign_placements(placement_id);
create index if not exists idx_creatives_campaign_id on creatives(campaign_id);
create index if not exists idx_permits_property_id on permits(property_id);
create index if not exists idx_installations_campaign_placement_id on installations(campaign_placement_id);
create index if not exists idx_incidents_property_id on incidents(property_id);
create index if not exists idx_payouts_campaign_id on payouts(campaign_id);
create index if not exists idx_documents_property_id on documents(property_id);
create index if not exists idx_messages_thread_id on messages(thread_id);
create index if not exists idx_audit_logs_entity on audit_logs(entity_type, entity_id);
create index if not exists idx_parcel_profiles_address on parcel_profiles(normalized_address);
create index if not exists idx_traffic_counts_road_year on traffic_counts(road_name, year);

alter table owners enable row level security;
alter table users enable row level security;
alter table organizations enable row level security;
alter table organization_members enable row level security;
alter table parcel_profiles enable row level security;
alter table properties enable row level security;
alter table property_claims enable row level security;
alter table file_assets enable row level security;
alter table placements enable row level security;
alter table placement_rules enable row level security;
alter table placement_availability enable row level security;
alter table valuation_runs enable row level security;
alter table traffic_counts enable row level security;
alter table zoning_records enable row level security;
alter table compliance_reviews enable row level security;
alter table advertisers enable row level security;
alter table campaigns enable row level security;
alter table campaign_placements enable row level security;
alter table creatives enable row level security;
alter table creative_reviews enable row level security;
alter table permits enable row level security;
alter table installations enable row level security;
alter table inspections enable row level security;
alter table proof_of_display enable row level security;
alter table incidents enable row level security;
alter table payouts enable row level security;
alter table payout_line_items enable row level security;
alter table documents enable row level security;
alter table message_threads enable row level security;
alter table messages enable row level security;
alter table agents enable row level security;
alter table agent_assignments enable row level security;
alter table audit_logs enable row level security;
