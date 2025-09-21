A blockchain-based smart contract system for tracking and verifying sustainable fishing catches, preventing overfishing and ensuring seafood traceability.

## 🌊 Features

- 🚤 **Boat Registration**: Register and verify fishing vessels with IoT device integration
- 📊 **Dynamic Quota Management**: Set and track fishing quotas per species and vessel
- 🐠 **Catch Recording**: IoT-verified catch logging with GPS coordinates and timestamps  
- 📱 **QR Code Traceability**: Generate unique QR codes for seafood supply chain tracking
- ✅ **Verification System**: Multi-level verification for catches and supply chain integrity
- 🔒 **Access Control**: Role-based permissions for boat owners, verifiers, and administrators

## 🚀 Quick Start

### Deploy Contract
```bash
clarinet console
(contract-call? .Sustainable-Fisheries---Catch-Certification register-boat "BOAT001" "Ocean Explorer" "FL-2024-001" "IOT-DEVICE-001")
```

### Register a Fishing Vessel
```clarity
(contract-call? .Sustainable-Fisheries---Catch-Certification register-boat 
  "BOAT001" 
  "Ocean Explorer" 
  "FL-2024-001" 
  "IOT-DEVICE-001")
```

### Set Fishing Quota
```clarity
(contract-call? .Sustainable-Fisheries---Catch-Certification set-species-quota
  "TUNA"
  "BOAT001" 
  u10000
  u1000
  u2000)
```

### Record a Catch
```clarity
(contract-call? .Sustainable-Fisheries---Catch-Certification record-catch
  "BOAT001"
  "TUNA"
  u500
  25123456
  -80456789
  "IOT-DEVICE-001")
```

### Verify QR Code
```clarity
(contract-call? .Sustainable-Fisheries---Catch-Certification verify-qr-code "BOAT001-1")
```

## 📋 Contract Functions

### 🔧 Admin Functions
- `verify-boat(boat-id)` - Verify a registered boat
- `set-species-quota(species, boat-id, quota, season-start, season-end)` - Set fishing quotas
- `add-verifier(verifier)` - Add authorized catch verifier
- `remove-verifier(verifier)` - Remove catch verifier
- `update-quota(species, boat-id, new-quota)` - Update existing quota

### 🚤 Boat Owner Functions
- `register-boat(boat-id, vessel-name, license, iot-device-id)` - Register new vessel
- `update-iot-device(boat-id, new-iot-device-id)` - Update IoT device ID for verified boats
- `record-catch(boat-id, species, weight, lat, lon, iot-device-id)` - Log new catch

### ✅ Verifier Functions
- `verify-catch(catch-id)` - Verify recorded catch

### 📖 Read-Only Functions
- `get-boat-info(boat-id)` - Get boat registration details
- `get-catch-info(catch-id)` - Get catch record details  
- `get-quota-info(species, boat-id)` - Get quota information
- `get-qr-info(qr-code)` - Get QR code details
- `get-remaining-quota(species, boat-id)` - Check remaining quota
- `is-catch-valid(catch-id)` - Check if catch is IoT and manually verified
- `validate-supply-chain(qr-code)` - Full supply chain validation

## 🔄 Workflow

1. **🚢 Boat Registration**: Vessel owner registers boat with IoT device ID
2. **✅ Verification**: Admin verifies boat credentials and licenses  
3. **📊 Quota Setting**: Admin sets species-specific quotas for verified boats
4. **🎣 Catch Recording**: IoT device automatically records catch with GPS/timestamp
5. **📱 QR Generation**: System generates unique QR code for traceability
6. **🔍 Catch Verification**: Authorized verifiers confirm catch validity
7. **🛒 Consumer Scanning**: End consumers scan QR codes to verify authenticity

## 🛡️ Security Features

- IoT device verification prevents spoofed catch records
- Multi-signature verification system
- Quota enforcement at blockchain level  
- Time-based QR code expiry
- GPS coordinate validation
- Role-based access control

## 📊 Data Structures

- **Boats**: Registration, ownership, IoT device mapping
- **Species Quotas**: Annual limits, usage tracking, seasonal windows
- **Catch Records**: Weight, location, timestamps, verification status
- **QR Registry**: Traceability codes with expiry and verification
- **Verifiers**: Authorized personnel for catch validation

## 🌍 Impact

This system helps combat illegal fishing by providing:
- Transparent catch tracking from boat to consumer
- Automated quota enforcement  
- Immutable record keeping
- Real-time IoT verification
- End-to-end supply chain visibility
