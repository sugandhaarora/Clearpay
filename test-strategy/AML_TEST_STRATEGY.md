# ClearPay — AML Test Strategy

**Version:** 1.0  
**Prepared by:** Sugandha Arora  
**Date:** April 2026  
**Status:** Final

---

## 1. Objective

This document defines the Anti-Money Laundering (AML) test strategy for ClearPay. It covers the test approach, risk areas, and regulatory obligations specific to AML compliance under FINTRAC guidelines. It supplements the main ClearPay Test Strategy and should be read alongside it.

ClearPay is obligated as a money services business (MSB) to detect, prevent, and report activities consistent with money laundering and terrorist financing under the Proceeds of Crime (Money Laundering) and Terrorist Financing Act (PCMLTFA).

---

## 2. Regulatory Context

| Regulation | Obligation |
|---|---|
| PCMLTFA | Primary Canadian AML legislation governing MSBs |
| FINTRAC — Large Cash Transaction Report (LCTR) | Report single transactions ≥ $10,000 |
| FINTRAC — Suspicious Transaction Report (STR) | Report transactions suspected of being linked to money laundering |
| FINTRAC — Terrorist Property Report (TPR) | Report property owned or controlled by terrorist entities |
| OSFI AML Guidelines | Risk-based approach to AML program design |
| PIPEDA | Governs retention and handling of AML-related personal data |

---

## 3. AML Risk Areas

### 3.1 Structuring (Smurfing)
Breaking large amounts into smaller transactions to avoid the $10,000 FINTRAC reporting threshold. ClearPay must detect patterns where a user sends multiple transfers that cumulatively approach or exceed $10,000 within a defined window.

### 3.2 Politically Exposed Persons (PEP)
Users identified as PEPs (foreign or domestic government officials and their associates) represent elevated AML risk. ClearPay must screen users against PEP lists at onboarding and flag matches for enhanced due diligence.

### 3.3 Sanctions Screening
Users and transaction recipients must be screened against OSFI and OFAC sanctions lists. Any match must block the transaction and trigger an alert.

### 3.4 Transaction Velocity and Unusual Patterns
Rapid or high-volume transactions inconsistent with a user's normal behaviour must trigger suspicious activity review. This includes sudden large transfers, dormant accounts becoming active, and round-number transactions.

### 3.5 High-Risk Jurisdictions
Transfers to or from jurisdictions identified as high-risk by FATF must be flagged for additional scrutiny.

---

## 4. AML Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Test Coverage |
|---|---|---|---|---|---|
| AML-R01 | User structures transfers just below $10,000 threshold to avoid FINTRAC reporting | High | High | Detect cumulative transfers approaching $10,000 within 24-hour window | TC-AML-001, TC-AML-002 |
| AML-R02 | PEP user onboards without enhanced due diligence trigger | Medium | High | Screen all users against PEP list at registration and periodically | TC-AML-005, TC-AML-006 |
| AML-R03 | Sanctioned individual completes registration and transacts | Low | High | Screen against OSFI and OFAC sanctions lists at onboarding and per transaction | TC-AML-007, TC-AML-008 |
| AML-R04 | Dormant account suddenly initiates high-value transfers | Medium | High | Flag accounts inactive for 90+ days initiating transfers over $1,000 | TC-AML-010 |
| AML-R05 | Multiple round-number transfers in short period not flagged | Medium | Medium | Detect repeated round-number transactions as suspicious pattern | TC-AML-011 |
| AML-R06 | Transfer to high-risk jurisdiction not flagged | Low | High | Validate jurisdiction risk scoring at transaction initiation | TC-AML-012 |
| AML-R07 | STR not generated for flagged suspicious transaction | Low | High | Validate internal STR workflow triggers correctly on flagged transactions | TC-AML-013 |
| AML-R08 | AML alert dismissed without mandatory review note | Medium | Medium | Validate alert closure requires documented review reason | TC-AML-014 |

---

## 5. AML Test Approach

### Risk-Based Prioritization
AML test cases are prioritized by regulatory impact. Structuring detection, sanctions screening, and STR generation are Sev-1 equivalent — failure in these areas constitutes direct regulatory non-compliance.

### Test Data Requirements
- Synthetic user profiles mimicking PEP and sanctioned individuals (no real data)
- Transaction sequences designed to simulate structuring patterns
- Jurisdiction codes covering FATF high-risk countries
- Dormant account profiles with 90+ day inactivity

### Test Environment Notes
- AML screening rules must be active in test environment
- Sanctions list must be loaded with synthetic test entries
- FINTRAC reporting endpoints must be stubbed for test environment validation

---

## 6. AML Entry and Exit Criteria

### Entry Criteria
- AML screening rules deployed and active in test environment
- Synthetic PEP and sanctions test data seeded
- Transaction monitoring rules configured per product specification

### Exit Criteria
- Zero open Sev-1 defects related to AML detection or reporting
- 100% execution of all FINTRAC-mapped test cases
- STR and LCTR trigger validation passed
- AML risk register reviewed and all high-impact risks covered

---

## 7. AML Compliance Mapping

| FINTRAC Obligation | Test Coverage |
|---|---|
| Large Cash Transaction Report (≥ $10,000) | TC-TXN-003, TC-TXN-004, TC-TXN-005 |
| Suspicious Transaction Report | TC-AML-013 |
| Structuring detection | TC-AML-001, TC-AML-002, TC-AML-003, TC-AML-004 |
| PEP screening at onboarding | TC-AML-005, TC-AML-006 |
| Sanctions screening | TC-AML-007, TC-AML-008, TC-AML-009 |
| High-risk jurisdiction flagging | TC-AML-012 |
| Dormant account monitoring | TC-AML-010 |
| Round-number transaction pattern detection | TC-AML-011 |
| Alert closure documentation | TC-AML-014 |
