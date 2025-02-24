# ID Tracker Smart Contract

A Clarity smart contract for managing and tracking IDs with verification capabilities. This contract enables transparent tracking of ID lifecycles, including status updates, verifications, and complete history tracking.

## Features

- **ID Management**
  - Register new IDs with initial status
  - Update ID status with automatic history tracking
  - View complete ID history and current status

- **Verification System**
  - Multiple verification types (Identity, Documents, Background, Biometric)
  - Authorized verifier management
  - Add and revoke verifications
  - Verify specific checks

- **Security**
  - Role-based access control
  - Input validation for all operations
  - History tracking with timestamps
  - Verifier authorization system

## Status Types

The contract supports the following ID statuses:
- `STATUS_CREATED` (1): Initial state
- `STATUS_ACTIVE` (2): ID is active
- `STATUS_PENDING_REVIEW` (3): Under review
- `STATUS_VERIFIED` (4): Fully verified

## Verification Types

Available verification check types:
- `CHECK_IDENTITY` (1): Basic identity verification
- `CHECK_DOCUMENTS` (2): Document verification
- `CHECK_BACKGROUND` (3): Background check
- `CHECK_BIOMETRIC` (4): Biometric verification

## Key Functions

### Public Functions

```clarity
(register-id (tracking-id uint) (initial-status uint))
(update-id-status (tracking-id uint) (new-status uint))
(add-authorized-verifier (verifier principal) (check-type uint))
(add-verification (tracking-id uint) (check-type uint))
(revoke-verification (tracking-id uint) (check-type uint))
```

### Read-Only Functions

```clarity
(verify-check (tracking-id uint) (check-type uint))
(get-id-history (tracking-id uint))
(get-id-status (tracking-id uint))
(get-verification-details (tracking-id uint) (check-type uint))
```

## Usage

1. Deploy the contract
2. Set up authorized verifiers using `add-authorized-verifier`
3. Register IDs using `register-id`
4. Update status as needed with `update-id-status`
5. Add verifications using `add-verification`
6. Query status and verifications using read-only functions

## Error Handling

The contract includes comprehensive error handling:
- `ERR_NOT_AUTHORIZED` (1): Unauthorized access
- `ERR_INVALID_ID` (2): Invalid tracking ID
- `ERR_STATUS_UPDATE_FAILED` (3): Status update failure
- `ERR_INVALID_STATUS` (4): Invalid status value
- `ERR_INVALID_CHECK` (5): Invalid check type
- `ERR_CHECK_EXISTS` (6): Verification already exists
- `ERR_INVALID_VERIFIER` (7): Invalid verifier principal

## Security Considerations

- Only system admin can add authorized verifiers
- Verifiers cannot self-authorize
- All inputs are validated before processing
- History tracking is automatic and immutable
- Status updates require proper authorization