# 🌳 WattShare - Referral Bounty System

A multi-level referral rewards platform built on Stacks blockchain using Clarity smart contracts.

## 🎯 What It Does

WattShare implements a tree-structured referral system that rewards users for bringing verified members to the platform. The system supports **three levels of referrals**, creating an incentive structure that encourages organic network growth.

### 💰 Reward Structure

- **Level 1** (Direct Referrals): 1,000,000 micro-STX
- **Level 2** (Referrals of Referrals): 500,000 micro-STX  
- **Level 3** (Third-Level Referrals): 250,000 micro-STX

## ✨ Features

- 📝 User registration with optional referrer
- ✅ Admin verification system for new users
- 🎁 Automatic multi-level reward distribution
- 🌲 Referral tree tracking (up to 100 users per level)
- 💸 Claimable pending rewards
- ⚙️ Configurable reward rates (owner only)
- 💵 Contract funding mechanism

## 🚀 Usage

### Register as a New User

```clarity
(contract-call? .wattshare register none)
```

### Register with a Referrer

```clarity
(contract-call? .wattshare register (some 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7))
```

### Verify a User (Owner Only)

```clarity
(contract-call? .wattshare verify-user 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Claim Your Rewards

```clarity
(contract-call? .wattshare claim-rewards)
```

### Fund the Contract

```clarity
(contract-call? .wattshare fund-contract u10000000)
```

### Check User Information

```clarity
(contract-call? .wattshare get-user-info 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### View Referral Tree

```clarity
(contract-call? .wattshare get-referral-tree 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Check Pending Rewards

```clarity
(contract-call? .wattshare get-pending-rewards 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🔧 Admin Functions

### Update Reward Rates

```clarity
(contract-call? .wattshare set-base-reward u2000000)
(contract-call? .wattshare set-level-two-reward u1000000)
(contract-call? .wattshare set-level-three-reward u500000)
```

### Check Contract Balance

```clarity
(contract-call? .wattshare get-contract-balance)
```

### View Current Reward Rates

```clarity
(contract-call? .wattshare get-reward-rates)
```

## 🎓 What You'll Learn

- **Tree Data Structures**: Implementing hierarchical referral relationships
- **Multi-level Recursion**: Processing rewards across multiple levels
- **Map Management**: Efficient storage and retrieval of user data
- **Optional Types**: Handling nullable referrer relationships
- **Access Control**: Owner-only administrative functions
- **Token Transfers**: Managing STX transfers and contract balances
- **Error Handling**: Comprehensive validation and error codes

## 📋 Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner-only function |
| u101 | User already registered |
| u102 | User not registered |
| u103 | Invalid referrer |
| u104 | Self-referral not allowed |
| u105 | Insufficient balance |
| u106 | User already verified |
| u107 | User not verified |
| u108 | Invalid referral level |

## 🏗️ Architecture

The contract uses three main data structures:

1. **users map**: Stores user registration data, verification status, and earnings
2. **referral-tree map**: Maintains the three-level referral hierarchy
3. **pending-rewards map**: Tracks claimable rewards for each user

## 🔐 Security Features

- Self-referral prevention
- Referrer validation before registration
- Verification requirement before reward claims
- Owner-only administrative controls
- Balance checks before transfers

## 📦 Installation

1. Clone this repository
2. Ensure you have Clarinet installed
3. Deploy the contract to your preferred network
4. Fund the contract with STX
5. Start inviting users!

## 🤝 Contributing

This is an MVP implementation. Contributions welcome!

## 📄 License

MIT

---

Built with ❤️ using Clarity