# GDPR Compliance Implementation Plan for Polis

## Overview
This document outlines the changes required to make Polis GDPR compliant based on analysis of the current codebase.

## Current State Analysis

### ✅ Existing GDPR Features
- Basic privacy policy (`client-admin/src/content/privacy.md`)
- IP address encryption in `server/src/participant.ts`
- Anonymous participation through XID system
- Some EU data subject rights documentation
- Third-party processor disclosure

### ❌ Major Gaps
- No consent management system
- Missing data subject rights implementation
- No cookie consent mechanism
- Incomplete data protection by design
- No breach notification procedures

## Phase 1: Critical Compliance (Immediate)

### 1.1 Cookie Consent System
**Priority: CRITICAL**
**Files to modify:**
- `client-participation/public/index.ejs`
- `client-admin/src/components/`

**Implementation:**
```javascript
// Add to client-participation
const CookieConsent = {
  required: ['session', 'security'],
  analytics: ['google-analytics'],
  marketing: [],
  preferences: localStorage.getItem('cookie-preferences')
};
```

### 1.2 Consent Management API
**Priority: CRITICAL** 
**Files to create:**
- `server/src/routes/consent.ts`
- `server/postgres/migrations/000015_create_consent_tables.sql`

**Database Schema:**
```sql
CREATE TABLE consent_records (
  id SERIAL PRIMARY KEY,
  participant_id INTEGER,
  consent_type VARCHAR(50) NOT NULL,
  consented BOOLEAN NOT NULL,
  consent_date BIGINT NOT NULL,
  withdrawn_date BIGINT,
  legal_basis VARCHAR(100) NOT NULL
);
```

### 1.3 Data Subject Rights API
**Priority: HIGH**
**Files to create:**
- `server/src/routes/data-subject-rights.ts`

**Endpoints:**
```typescript
// Right to Access (Article 15)
GET /api/v3/data-subject/export/:pid
// Right to Rectification (Article 16) 
PUT /api/v3/data-subject/update/:pid
// Right to Erasure (Article 17)
DELETE /api/v3/data-subject/delete/:pid
// Right to Object (Article 21)
POST /api/v3/data-subject/object/:pid
// Data Portability (Article 20)
GET /api/v3/data-subject/portability/:pid
```

## Phase 2: Enhanced Protection (30 days)

### 2.1 Enhanced Pseudonymization
**Files to modify:**
- `server/src/participant.ts`
- `server/src/crypto.ts` (create)

**Implementation:**
```typescript
function pseudonymizeIdentifier(data: string, salt: string): string {
  return crypto.createHash('sha256')
    .update(data + salt + Config.pseudonymizationSecret)
    .digest('hex');
}
```

### 2.2 Automated Data Retention
**Files to create:**
- `server/src/jobs/data-retention.ts`
- `server/postgres/migrations/000016_add_retention_policies.sql`

### 2.3 Privacy Dashboard
**Files to create:**
- `client-admin/src/pages/PrivacyDashboard.tsx`
- `client-participation/js/components/PrivacyControls.js`

## Phase 3: Governance & Documentation (60 days)

### 3.1 Data Processing Records
**Files to create:**
- `docs/data-processing-inventory.md`
- `docs/retention-schedule.md`
- `docs/legitimate-interests-assessment.md`

### 3.2 Breach Notification System
**Files to create:**
- `server/src/services/breach-detection.ts`
- `server/src/routes/breach-notification.ts`

### 3.3 Privacy Impact Assessment
**Files to create:**
- `docs/privacy-impact-assessment.md`
- `docs/gdpr-compliance-procedures.md`

## Legal Basis Mapping

| Data Type | Legal Basis | Article 6 Ground |
|-----------|-------------|------------------|
| IP Address | Legitimate Interest | Article 6(1)(f) |
| Votes/Comments | Consent | Article 6(1)(a) |
| Analytics | Consent | Article 6(1)(a) |
| Security Logs | Legitimate Interest | Article 6(1)(f) |
| Account Data | Contract Performance | Article 6(1)(b) |

## Technical Requirements

### Database Changes
```sql
-- Add consent tracking
ALTER TABLE participants_extended 
  ADD COLUMN gdpr_consent_analytics BOOLEAN DEFAULT FALSE,
  ADD COLUMN gdpr_consent_date BIGINT,
  ADD COLUMN gdpr_consent_marketing BOOLEAN DEFAULT FALSE;

-- Add retention dates
ALTER TABLE conversations 
  ADD COLUMN data_retention_days INTEGER DEFAULT 1095; -- 3 years
```

### Environment Variables
```bash
# Add to .env
GDPR_COMPLIANCE_MODE=true
DATA_RETENTION_DEFAULT_DAYS=1095
PSEUDONYMIZATION_SECRET=your-secret-key
BREACH_NOTIFICATION_EMAIL=dpo@your-domain.com
```

## Testing Requirements
- [ ] Cookie consent flow testing
- [ ] Data export functionality testing  
- [ ] Data deletion verification
- [ ] Consent withdrawal testing
- [ ] Cross-border data transfer compliance

## Risk Assessment

### High Risk
- **No cookie consent**: €4-20M fine risk
- **Missing data subject rights**: €4-20M fine risk
- **No legal basis documentation**: Regulatory investigation risk

### Medium Risk  
- **Incomplete pseudonymization**: Data protection violation
- **No breach procedures**: 72-hour notification violation

### Low Risk
- **Documentation gaps**: Administrative requirements only

## Next Steps
1. Implement Phase 1 (Critical) within 2 weeks
2. Set up privacy-by-design development process
3. Conduct staff GDPR training
4. Engage data protection legal counsel
5. Prepare for regulatory submission if required

## Resources
- [GDPR.eu Compliance Checklist](https://gdpr.eu/checklist/)
- [ICO GDPR Guidance](https://ico.org.uk/for-organisations/guide-to-data-protection/guide-to-the-general-data-protection-regulation-gdpr/)
- [Article 29 Working Party Guidelines](https://ec.europa.eu/newsroom/article29/items/612053)