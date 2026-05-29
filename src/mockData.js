export const mockData = {
  properties: [
    {
      id: 'demo-property-1',
      name: 'Market Street Corner Lot',
      address: '403 N Market St',
      city: 'Washington',
      state: 'NC',
      property_type: 'Commercial frontage',
      zoning: 'B1H',
      historic_district: true,
      traffic_estimate: 14200,
      verification_status: 'unverified',
      compliance_status: 'manual_review_needed'
    },
    {
      id: 'demo-property-2',
      name: 'Highway Retail Pad',
      address: 'US-264 Business Corridor',
      city: 'Washington',
      state: 'NC',
      property_type: 'Retail / parking lot',
      zoning: 'Commercial',
      historic_district: false,
      traffic_estimate: 23100,
      verification_status: 'verified',
      compliance_status: 'permit_likely_required'
    }
  ],
  placements: [
    {
      id: 'demo-placement-1',
      property_id: 'demo-property-1',
      name: 'Frontage trailer space',
      placement_type: 'Trailer parking area',
      dimensions: '8 ft x 20 ft',
      facing_direction: 'Southbound',
      facing_street: 'Market St',
      visibility_score: 82,
      traffic_estimate: 14200,
      allowed_formats: ['Wrapped trailer', 'Temporary sign'],
      blocked_categories: ['Political', 'Adult', 'Tobacco'],
      estimated_monthly_low: 400,
      estimated_monthly_high: 1200,
      status: 'review'
    },
    {
      id: 'demo-placement-2',
      property_id: 'demo-property-2',
      name: 'Fence line panel',
      placement_type: 'Fence line',
      dimensions: '4 ft x 24 ft',
      facing_direction: 'Eastbound',
      facing_street: 'US-264 Business',
      visibility_score: 74,
      traffic_estimate: 23100,
      allowed_formats: ['Banner', 'Panel'],
      blocked_categories: ['Cannabis', 'Adult'],
      estimated_monthly_low: 700,
      estimated_monthly_high: 1800,
      status: 'active'
    }
  ],
  advertisers: [
    { id: 'demo-advertiser-1', name: 'Harbor Dental', category: 'Healthcare', contact_name: 'Local buyer' },
    { id: 'demo-advertiser-2', name: 'Regional Bank Campaign', category: 'Financial services', contact_name: 'Media planner' }
  ],
  campaigns: [
    {
      id: 'demo-campaign-1',
      title: 'June New Patient Push',
      advertiser_id: 'demo-advertiser-1',
      placement_id: 'demo-placement-1',
      start_date: '2026-06-01',
      end_date: '2026-06-30',
      gross_price: 1500,
      owner_payout: 1125,
      status: 'pending_owner_approval',
      compliance_status: 'manual_review_needed',
      installation_status: 'not_scheduled'
    },
    {
      id: 'demo-campaign-2',
      title: 'Summer Checking Offer',
      advertiser_id: 'demo-advertiser-2',
      placement_id: 'demo-placement-2',
      start_date: '2026-07-01',
      end_date: '2026-08-31',
      gross_price: 3600,
      owner_payout: 2700,
      status: 'approved',
      compliance_status: 'permit_likely_required',
      installation_status: 'scheduled'
    }
  ],
  payouts: [
    { id: 'demo-payout-1', net_payout: 1125, gross_amount: 1500, fees: 375, status: 'scheduled', payment_date: '2026-07-05', tax_year: 2026 }
  ],
  incidents: [
    { id: 'demo-incident-1', type: 'Neighbor complaint', severity: 'normal', status: 'under_review', description: 'Demo issue queue for owner support workflow.' }
  ],
  documents: [],
  messages: []
}
