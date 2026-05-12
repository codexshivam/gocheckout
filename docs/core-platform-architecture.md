# Core Platform Architecture (MVP)

This document defines the core data architecture and business logic for GoCheckout MVP, excluding external integrations (WhatsApp/logistics).

## 1) Identity and Business Separation

### `users/{uid}`
- `name` (string)
- `phone` (string)
- `email` (string)
- `activeStoreId` (string)

### `stores/{storeId}`
- `businessName` (string)
- `businessAddress` (string)
- `contactInfo` (map: `email`, `phone`)
- `storeLogoUrl` (string; Cloudflare R2 public URL)
- `verificationStatus` (`pending|verified|rejected`)
- `team` (array of map: `{userId, role}`)
- `subscription` (map)
  - `plan` (`trial|pro`)
  - `status` (`active|past_due`)
  - `expiresAt` (timestamp)

### `stores/{storeId}/private_settings/{docId}`
- Owner-only read/write (via RBAC in security rules)
- `verification` doc: KYC/verification document URLs (R2)
- `payments` doc: payment API credentials / bank details

## 2) Product and Variant Engine

### `products/{productId}`
- `storeId` (string)
- `name` (string)
- `basePrice` (number)
- `attributes` (array, e.g. `["Color", "Size"]`)
- `variants` (array)
  - `variantId` (string)
  - `options` (map, e.g. `{Color: Black, Size: XL}`)
  - `price` (number)
  - `inventoryCount` (int)
  - `isInventoryTracked` (bool)
  - `imageUrl` (string; R2)

## 3) Smart Checkout Links

### `checkout_links/{linkId}`
- `storeId` (string)
- `items` (array)
  - `productId`, `variantId`, `quantity`, `unitPrice`
- `financials` (map)
  - `subtotal`
  - `extraCharges` (array: `{name, amount}`)
  - `discount` (map: `{type, amountDeducted}`)
  - `totalAmount`
- `status` (`active|converted|expired`)
- `convertedToOrderId` (string, optional)

## 4) Order Ledger + Split Payments

### `orders/{orderId}`
- `storeId` (string)
- `origin` (`checkout_link|manual`)
- `sourceLinkId` (string, optional)
- `items`, `financials`, `customerInfo`
- `paymentSummary` (map)
  - `totalPaid`
  - `balanceDue`
  - `paymentStatus` (`unpaid|partially_paid|fully_paid`)
- `paymentLedger` (array)
  - entries: `{method, amount, proofUrl?, status, recordedAt?}`
- `shippingTimeline`
  - `createdAt`, `shippedAt`, `deliveredAt`, `rtoAt`

## 5) Business Flow

1. Owner account creates store and manages plan/subscription.
2. Owner adds team members with role-based permissions.
3. Chat agent builds checkout link with variant-level items and optional charges/discount.
4. Buyer pays advance (optional) and uploads proof.
5. System converts checkout link to order and appends ledger entry.
6. Payment summary updates (`totalPaid`, `balanceDue`, status transitions).

## 6) Implementation Notes

- Legacy `merchantId` fields are still accepted in models for backward compatibility.
- New model path constants are users/stores-first; merchant aliases remain temporary.
- Security rules should enforce owner-only access to `private_settings` and role-based write scopes for team operations.
