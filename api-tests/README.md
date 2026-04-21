# ClearPay API Tests — Postman Collection

## Overview
This folder contains a Postman collection of API tests for ClearPay's currency and transaction rate validation layer. Tests are built against the ExchangeRate API (open.er-api.com) to simulate the kind of API contract validation performed on a real payments platform.

## What Is Being Tested
ClearPay processes cross-currency e-transfers. The API layer must return accurate, timely exchange rate data with a consistent response schema. These tests validate that the API behaves correctly under both valid and invalid conditions.

## Test Coverage

| Request | What It Validates |
|---|---|
| GET valid base currency - CAD | 200 response, success result, correct base code, rates present |
| GET valid base currency - USD | 200 response, CAD rate present and positive |
| GET invalid currency code - ZZZ | Error result returned in response body for unsupported currency |
| GET CAD to USD rate range validation | USD rate is a number, positive, within realistic CAD/USD range |
| GET response schema validation - CAD | All required fields present, no sensitive fields exposed |
| GET multiple currency rates validation | USD, EUR, GBP rates positive, CAD to CAD rate exactly 1 |
| GET timestamp validation - CAD | Timestamps present, next update after last update, data within 48 hours |

## Key Testing Note
This API returns HTTP 200 for invalid currency codes with `result: error` in the response body rather than returning a 404. Tests validate error state via response body rather than HTTP status code. This reflects a real-world scenario where API contract testing must account for non-standard error handling patterns.

## How to Import and Run
1. Download `ClearPay-API-Tests.json` from this folder
2. Open Postman
3. Click "Import" → select the JSON file
4. Open the collection and click "Run collection"
5. All 39 tests should pass

## Tools Used
- Postman (free desktop app)
- ExchangeRate API free tier — no authentication required
