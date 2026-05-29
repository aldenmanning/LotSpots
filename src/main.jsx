import React, { useEffect, useMemo, useState } from 'react'
import { createRoot } from 'react-dom/client'
import {
  AlertTriangle,
  Banknote,
  Building2,
  CalendarDays,
  CheckCircle2,
  ClipboardCheck,
  FileText,
  LayoutDashboard,
  MapPin,
  Megaphone,
  MessageSquare,
  ShieldCheck,
  Sparkles,
  Wrench
} from 'lucide-react'
import { supabase, hasSupabaseConfig } from './supabaseClient'
import { mockData } from './mockData'
import './styles.css'

const TABLES = ['properties', 'placements', 'advertisers', 'campaigns', 'incidents', 'payouts']

function formatMoney(value) {
  if (value === null || value === undefined) return '—'
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value)
}

function humanize(value) {
  if (!value) return '—'
  return String(value).replaceAll('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

function StatusPill({ value }) {
  const clean = value || 'unknown'
  const tone = clean.includes('approved') || clean.includes('active') || clean.includes('verified') ? 'good' : clean.includes('review') || clean.includes('needed') || clean.includes('required') ? 'warn' : 'neutral'
  return <span className={`pill ${tone}`}>{humanize(clean)}</span>
}

function StatCard({ icon: Icon, label, value, helper }) {
  return (
    <section className="stat-card">
      <div className="stat-icon"><Icon size={20} /></div>
      <div>
        <div className="stat-label">{label}</div>
        <div className="stat-value">{value}</div>
        {helper && <div className="stat-helper">{helper}</div>}
      </div>
    </section>
  )
}

function SectionHeader({ icon: Icon, title, children }) {
  return (
    <div className="section-header">
      <div>
        <div className="eyebrow"><Icon size={15} /> LotSpots Console</div>
        <h2>{title}</h2>
      </div>
      {children}
    </div>
  )
}

function App() {
  const [active, setActive] = useState('dashboard')
  const [data, setData] = useState(mockData)
  const [loading, setLoading] = useState(hasSupabaseConfig)
  const [error, setError] = useState(null)

  useEffect(() => {
    async function load() {
      if (!supabase) return
      setLoading(true)
      const next = {}
      for (const table of TABLES) {
        const { data, error } = await supabase.from(table).select('*').limit(100)
        if (error) {
          setError(`${table}: ${error.message}`)
          next[table] = mockData[table] || []
        } else {
          next[table] = data?.length ? data : mockData[table] || []
        }
      }
      setData((current) => ({ ...current, ...next }))
      setLoading(false)
    }
    load()
  }, [])

  const metrics = useMemo(() => {
    const activeCampaigns = data.campaigns.filter((c) => ['active', 'owner_approval_needed', 'compliance_review'].includes(c.status)).length
    const pendingApprovals = data.campaigns.filter((c) => String(c.status).includes('approval') || String(c.compliance_status).includes('review')).length
    const monthlyRange = data.placements.reduce((acc, p) => {
      acc.low += Number(p.estimated_monthly_low || 0)
      acc.high += Number(p.estimated_monthly_high || 0)
      return acc
    }, { low: 0, high: 0 })
    const openIssues = data.incidents.filter((i) => !['closed', 'resolved'].includes(i.status)).length
    return { activeCampaigns, pendingApprovals, monthlyRange, openIssues }
  }, [data])

  const nav = [
    ['dashboard', LayoutDashboard, 'Dashboard'],
    ['properties', Building2, 'Properties'],
    ['placements', MapPin, 'Ad Spaces'],
    ['campaigns', Megaphone, 'Campaigns'],
    ['compliance', ShieldCheck, 'Compliance'],
    ['payouts', Banknote, 'Payouts'],
    ['issues', AlertTriangle, 'Issues'],
    ['documents', FileText, 'Documents'],
    ['messages', MessageSquare, 'Messages']
  ]

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand-mark">LS</div>
        <div className="brand-copy">
          <strong>LotSpots</strong>
          <span>Physical media marketplace</span>
        </div>
        <nav>
          {nav.map(([key, Icon, label]) => (
            <button key={key} className={active === key ? 'active' : ''} onClick={() => setActive(key)}>
              <Icon size={18} /> {label}
            </button>
          ))}
        </nav>
      </aside>

      <main>
        <header className="topbar">
          <div>
            <h1>Property income dashboard</h1>
            <p>Track properties, ad spaces, campaigns, compliance, approvals, incidents, and payouts.</p>
          </div>
          <div className="connection-card">
            <span className={hasSupabaseConfig ? 'dot live' : 'dot'} />
            {hasSupabaseConfig ? 'Connected to Supabase' : 'Demo mode: add Supabase env vars'}
          </div>
        </header>

        {loading && <div className="notice">Loading Supabase data…</div>}
        {error && <div className="notice warning">Supabase fallback active: {error}</div>}

        {active === 'dashboard' && <Dashboard data={data} metrics={metrics} />}
        {active === 'properties' && <Properties data={data} />}
        {active === 'placements' && <Placements data={data} />}
        {active === 'campaigns' && <Campaigns data={data} />}
        {active === 'compliance' && <Compliance data={data} />}
        {active === 'payouts' && <Payouts data={data} />}
        {active === 'issues' && <Issues data={data} />}
        {active === 'documents' && <Placeholder icon={FileText} title="Documents" copy="Connect the documents table and Supabase Storage for agreements, permits, certificates, approvals, photos, payout statements, and tax documents." />}
        {active === 'messages' && <Placeholder icon={MessageSquare} title="Messages" copy="Connect the messages table for campaign questions, compliance notices, installation coordination, payment support, and owner support history." />}
      </main>
    </div>
  )
}

function Dashboard({ data, metrics }) {
  return (
    <>
      <div className="stats-grid">
        <StatCard icon={Megaphone} label="Active / pending campaigns" value={metrics.activeCampaigns} helper="Campaigns needing motion" />
        <StatCard icon={ClipboardCheck} label="Pending approvals" value={metrics.pendingApprovals} helper="Owner or compliance review" />
        <StatCard icon={Banknote} label="Estimated monthly value" value={`${formatMoney(metrics.monthlyRange.low)}–${formatMoney(metrics.monthlyRange.high)}`} helper="Based on listed ad spaces" />
        <StatCard icon={AlertTriangle} label="Open issues" value={metrics.openIssues} helper="Incidents not resolved" />
      </div>
      <section className="panel hero-panel">
        <div>
          <div className="eyebrow"><Sparkles size={15} /> Marketplace model</div>
          <h2>Owners list visibility. Advertisers buy exposure. LotSpots manages the workflow.</h2>
          <p>This dashboard is intentionally operational: properties, placements, campaigns, compliance, installation, incidents, documents, messages, and payouts.</p>
        </div>
      </section>
      <div className="two-column">
        <Campaigns data={data} compact />
        <Placements data={data} compact />
      </div>
    </>
  )
}

function Properties({ data }) {
  return (
    <section className="panel">
      <SectionHeader icon={Building2} title="Properties" />
      <div className="card-list">
        {data.properties.map((p) => (
          <article className="data-card" key={p.id}>
            <div className="card-top">
              <div>
                <h3>{p.name}</h3>
                <p>{p.address}, {p.city} {p.state}</p>
              </div>
              <StatusPill value={p.verification_status} />
            </div>
            <div className="detail-grid">
              <span>Type <strong>{p.property_type || '—'}</strong></span>
              <span>Zoning <strong>{p.zoning || '—'}</strong></span>
              <span>Traffic <strong>{p.traffic_estimate?.toLocaleString?.() || '—'}</strong></span>
              <span>Historic <strong>{p.historic_district ? 'Yes' : 'No'}</strong></span>
            </div>
            <div className="card-footer"><StatusPill value={p.compliance_status} /></div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Placements({ data, compact = false }) {
  const propertyName = (id) => data.properties.find((p) => p.id === id)?.name || 'Unassigned property'
  return (
    <section className="panel">
      <SectionHeader icon={MapPin} title={compact ? 'Top ad spaces' : 'Ad spaces'} />
      <div className="card-list">
        {data.placements.map((p) => (
          <article className="data-card" key={p.id}>
            <div className="card-top">
              <div>
                <h3>{p.name}</h3>
                <p>{propertyName(p.property_id)} · {p.placement_type}</p>
              </div>
              <StatusPill value={p.status} />
            </div>
            <div className="detail-grid">
              <span>Dimensions <strong>{p.dimensions || '—'}</strong></span>
              <span>Facing <strong>{p.facing_street || p.facing_direction || '—'}</strong></span>
              <span>Visibility <strong>{p.visibility_score || 0}/100</strong></span>
              <span>Value <strong>{formatMoney(p.estimated_monthly_low)}–{formatMoney(p.estimated_monthly_high)}</strong></span>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Campaigns({ data, compact = false }) {
  const advertiser = (id) => data.advertisers.find((a) => a.id === id)?.name || 'Unknown advertiser'
  const placement = (id) => data.placements.find((p) => p.id === id)?.name || 'Unknown placement'
  return (
    <section className="panel">
      <SectionHeader icon={Megaphone} title={compact ? 'Campaign queue' : 'Campaigns'} />
      <div className="card-list">
        {data.campaigns.map((c) => (
          <article className="data-card" key={c.id}>
            <div className="card-top">
              <div>
                <h3>{c.title}</h3>
                <p>{advertiser(c.advertiser_id)} · {placement(c.placement_id)}</p>
              </div>
              <StatusPill value={c.status} />
            </div>
            <div className="detail-grid">
              <span>Dates <strong>{c.start_date || '—'} → {c.end_date || '—'}</strong></span>
              <span>Gross <strong>{formatMoney(c.gross_price)}</strong></span>
              <span>Owner payout <strong>{formatMoney(c.owner_payout)}</strong></span>
              <span>Install <strong>{humanize(c.installation_status)}</strong></span>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Compliance({ data }) {
  return (
    <section className="panel">
      <SectionHeader icon={ShieldCheck} title="Compliance review" />
      <div className="workflow-grid">
        {data.properties.map((p) => (
          <article className="workflow-card" key={p.id}>
            <h3>{p.name}</h3>
            <p>{p.zoning || 'Unknown zoning'} · {p.historic_district ? 'Historic district' : 'No historic flag'}</p>
            <StatusPill value={p.compliance_status} />
            <ul>
              <li>Check sign ordinance</li>
              <li>Check DOT frontage risk</li>
              <li>Confirm temporary vs. permanent format</li>
              <li>Assign permit responsibility</li>
            </ul>
          </article>
        ))}
      </div>
    </section>
  )
}

function Payouts({ data }) {
  return (
    <section className="panel">
      <SectionHeader icon={Banknote} title="Payouts" />
      <div className="card-list">
        {data.payouts.map((p) => (
          <article className="data-card" key={p.id}>
            <div className="card-top">
              <div>
                <h3>{formatMoney(p.net_payout)}</h3>
                <p>Expected payment: {p.payment_date || '—'}</p>
              </div>
              <StatusPill value={p.status} />
            </div>
            <div className="detail-grid">
              <span>Gross <strong>{formatMoney(p.gross_amount)}</strong></span>
              <span>Fees <strong>{formatMoney(p.fees)}</strong></span>
              <span>Net <strong>{formatMoney(p.net_payout)}</strong></span>
              <span>Tax year <strong>{p.tax_year || new Date().getFullYear()}</strong></span>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Issues({ data }) {
  return (
    <section className="panel">
      <SectionHeader icon={Wrench} title="Damage, incidents, and complaints" />
      <div className="card-list">
        {data.incidents.map((i) => (
          <article className="data-card" key={i.id}>
            <div className="card-top">
              <div>
                <h3>{i.type}</h3>
                <p>{i.description}</p>
              </div>
              <StatusPill value={i.status} />
            </div>
            <div className="detail-grid">
              <span>Severity <strong>{humanize(i.severity)}</strong></span>
              <span>Created <strong>{i.created_at ? new Date(i.created_at).toLocaleDateString() : 'Demo'}</strong></span>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}

function Placeholder({ icon: Icon, title, copy }) {
  return (
    <section className="panel placeholder-panel">
      <Icon size={32} />
      <h2>{title}</h2>
      <p>{copy}</p>
    </section>
  )
}

createRoot(document.getElementById('root')).render(<App />)
