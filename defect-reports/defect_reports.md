# ClearPay — Defect Reports

**Project:** ClearPay Mobile Banking QA Framework  
**Prepared by:** Sugandha Arora  
**Environment:** Test  
**Status:** Sample defect reports for portfolio demonstration

---

## DEF-001 — KYC Approves User with Expired Government ID

| Field | Detail |
|---|---|
| **Defect ID** | DEF-001 |
| **Title** | KYC onboarding approves user presenting expired government ID |
| **Severity** | Sev-1 |
| **Priority** | High |
| **Status** | Open |
| **Module** | KYC Onboarding |
| **Test Case** | TC-KYC-005 |
| **Regulatory Ref** | FINTRAC KYC Obligations, PCMLTFA |
| **Environment** | Test — Build 2.1.4 |
| **Reported by** | Sugandha Arora |
| **Date** | April 2026 |

### Steps to Reproduce
1. Launch ClearPay app
2. Begin new user registration
3. Complete personal details form with valid name, DOB, and address
4. Upload a government-issued driver's licence expired 1 day ago
5. Submit KYC verification

### Expected Result
KYC verification fails. Error message displayed: "Your ID has expired. Please provide a valid, unexpired government-issued ID." Account is not activated.

### Actual Result
KYC verification passes. Account is activated and user is able to initiate e-transfers immediately despite presenting an expired ID.

### Impact
This defect constitutes a direct violation of FINTRAC KYC obligations under PCMLTFA. ClearPay is required to verify valid, current identity documents before activating any account. An expired ID is not acceptable proof of identity. If this defect reaches production, ClearPay is exposed to regulatory penalties, potential FINTRAC audit findings, and reputational risk. Any transactions completed by unverified users would also be non-compliant.

### Root Cause Analysis
Investigation of the onboarding validation logic revealed that the KYC service validates the format and presence of the ID document but does not check the `expiry_date` field against the current date. The expiry date is extracted from the uploaded document via OCR but is stored without being evaluated. The validation function contains the following gap:

validate_id(document):
check document_type is valid ✓
check document_number format ✓
check name matches registration form ✓
check expiry_date is present ✓
// Missing: check expiry_date > today()

The fix requires adding an expiry date comparison in the KYC validation service: `expiry_date > current_date`. This is a single-line logic addition but requires regression testing across all ID document types supported by the platform.

### Recommended Fix
Add expiry date validation in the KYC onboarding service:
- Check `expiry_date > current_date` for all submitted ID documents
- Return a specific error code for expired ID distinct from other KYC failures
- Re-test TC-KYC-003, TC-KYC-004, TC-KYC-005, TC-KYC-006 after fix

---

## DEF-002 — Duplicate E-Transfer Processed Within 60-Second Window

| Field | Detail |
|---|---|
| **Defect ID** | DEF-002 |
| **Title** | Duplicate e-transfer processed within 60-second window without user confirmation |
| **Severity** | Sev-2 |
| **Priority** | High |
| **Status** | Open |
| **Module** | E-Transfer |
| **Test Case** | TC-ETR-012 |
| **Regulatory Ref** | FINTRAC Suspicious Transaction |
| **Environment** | Test — Build 2.1.4 |
| **Reported by** | Sugandha Arora |
| **Date** | April 2026 |

### Steps to Reproduce
1. Log in as a valid KYC-approved user
2. Initiate e-transfer of $500 to recipient A
3. Submit transfer — confirm it processes successfully
4. Immediately initiate a second e-transfer of $500 to the same recipient A
5. Submit within 30 seconds of the first transfer

### Expected Result
System detects potential duplicate transfer. User is presented with a confirmation prompt: "This looks similar to a recent transfer. Did you mean to send $500 to Recipient A again?" User must explicitly confirm before second transfer is processed.

### Actual Result
Second transfer processes immediately without any duplicate detection prompt. $500 is debited a second time. User receives no warning.

### Impact
Users can unknowingly send duplicate payments with no safety net. In a financial application this represents a significant trust and usability failure. Repeated duplicates within a short window also match suspicious transaction patterns that should be flagged for FINTRAC review. This defect could result in financial loss for users and increased fraud exposure for ClearPay.

### Root Cause Analysis
The duplicate detection service checks for matching transactions but only evaluates sender ID and amount. It does not include recipient ID in the comparison key, meaning transfers to the same recipient are not caught. The current detection logic is:

is_duplicate(txn):
match on sender_id + amount + within 60s = flag
// Missing: recipient_id in match criteria

Adding `recipient_id` to the duplicate detection key would resolve this defect. A secondary fix should ensure the confirmation prompt UI is triggered correctly when a duplicate is detected.

### Recommended Fix
- Update duplicate detection logic to match on `sender_id + recipient_id + amount` within a 60-second window
- Implement confirmation prompt UI for flagged duplicates
- Re-test TC-ETR-012 and TC-AML-002 after fix

---

## DEF-003 — Session Remains Active 45 Minutes Beyond Inactivity Threshold

| Field | Detail |
|---|---|
| **Defect ID** | DEF-003 |
| **Title** | User session remains active 45 minutes beyond the 10-minute inactivity timeout |
| **Severity** | Sev-3 |
| **Priority** | Medium |
| **Status** | Open |
| **Module** | Session Management |
| **Test Case** | TC-SEC-001 |
| **Regulatory Ref** | PIPEDA s.4.7 — Safeguards |
| **Environment** | Test — Build 2.1.4 |
| **Reported by** | Sugandha Arora |
| **Date** | April 2026 |

### Steps to Reproduce
1. Log in to ClearPay on a test device
2. Navigate to the account summary screen
3. Leave the app idle — do not interact with it
4. Wait 15 minutes
5. Attempt to navigate to transaction history

### Expected Result
After 10 minutes of inactivity the session expires automatically. User is redirected to the login screen with message: "Your session has expired for security. Please log in again."

### Actual Result
Session remains active after 10 minutes. User can continue navigating and initiating transactions without re-authentication. Session was observed active up to 55 minutes after last user interaction.

### Impact
An active session beyond the inactivity threshold leaves the user's account exposed on unattended devices. For a financial application handling banking data and e-transfers, this is a meaningful security risk. It also constitutes a potential PIPEDA safeguards obligation gap as ClearPay is required to protect personal and financial data against unauthorized access.

### Root Cause Analysis
The session timeout timer is initialised correctly at login but is being reset by a background API polling call that the app makes every 5 minutes to refresh exchange rates. This polling call is being interpreted by the session management service as user activity, resetting the inactivity clock on each poll. The fix requires excluding background system calls from the session activity timer — only explicit user interactions should reset the inactivity clock.

### Recommended Fix
- Exclude background API polling calls from session activity timer
- Ensure only user-initiated interactions reset the inactivity clock
- Re-test TC-SEC-001 and TC-SEC-002 after fix
- Verify fix does not affect session behaviour during active use
