# ShieldGuard Protocol

A decentralized anti-phishing smart contract built on Stacks blockchain using Clarity language. ShieldGuard Protocol provides a community-driven approach to identifying and preventing phishing attacks through domain verification and reporting mechanisms.

## 🛡️ Overview

ShieldGuard Protocol creates a decentralized registry of verified domains and suspicious URLs, enabling users to check domain safety before visiting websites. The protocol incentivizes community participation through a stake-based verification system and rewards legitimate reporters of malicious domains.

## 🚀 Features

- **Stake-Based Domain Registration**: Users stake STX tokens to register domains for verification
- **Decentralized Verification**: Authorized verifiers can validate domains as safe or malicious
- **Community Reporting**: Users can report suspicious domains with evidence
- **Safety Checker**: Real-time domain safety verification
- **Reward System**: Reporters earn rewards for successfully identifying blacklisted domains
- **Multi-Status System**: Pending, Verified, Suspicious, and Blacklisted domain states
- **Reputation Scoring**: Domains build reputation based on verification and community reports

## 📁 Project Structure

```
shield-guard/
├── contracts/
│   └── domain-sentinel.clar          # Main anti-phishing smart contract
├── tests/
│   └── domain-sentinel_test.ts       # Contract test suite
├── settings/
│   ├── Devnet.toml                   # Development network configuration
│   ├── Testnet.toml                  # Testnet configuration
│   └── Mainnet.toml                  # Mainnet configuration
├── Clarinet.toml                     # Project configuration
├── README.md                         # This file
└── .gitignore                        # Git ignore rules
```

## 🔧 Smart Contract Details

### Contract Name: `domain-sentinel`

### Key Constants
- **MIN-STAKE**: 10 STX (minimum stake required for domain registration)
- **Domain Status**: Pending (0), Verified (1), Suspicious (2), Blacklisted (3)

### Core Functions

#### Public Functions

**`register-domain`**
- Register a new domain for verification
- Requires minimum stake of 10 STX
- Parameters: `domain` (string-ascii 256), `evidence-hash` (string-ascii 64)

**`verify-domain`**
- Authorized verifiers can update domain status
- Parameters: `domain` (string-ascii 256), `new-status` (uint)

**`report-suspicious-domain`**
- Community members can report malicious domains
- Parameters: `domain` (string-ascii 256), `evidence-hash` (string-ascii 64)

**`claim-report-reward`**
- Claim rewards for successful malicious domain reports
- Parameters: `domain` (string-ascii 256)

**`add-verifier`** / **`remove-verifier`**
- Admin functions to manage authorized verifiers
- Parameters: `verifier` (principal)

#### Read-Only Functions

**`is-domain-safe`**
- Check if a domain is safe to visit
- Returns: Safety status, reputation score, and report count
- Parameters: `domain` (string-ascii 256)

**`get-domain-info`**
- Retrieve complete domain information
- Parameters: `domain` (string-ascii 256)

**`get-contract-stats`**
- Get contract statistics including total stake and balance

### Data Maps

**`verified-domains`**
- Stores domain registration and verification data
- Key: `{ domain: string-ascii 256 }`
- Value: Owner, status, stake amount, verification date, reputation, reports count

**`user-reports`**
- Tracks user reports against suspicious domains
- Key: `{ reporter: principal, domain: string-ascii 256 }`
- Value: Report date, evidence hash, reward claimed status

**`authorized-verifiers`**
- Manages authorized domain verifiers
- Key: `{ verifier: principal }`
- Value: Authorization status and reputation

## 🔒 Security Features

- **Input Validation**: All user inputs are validated for format and length
- **Access Control**: Owner-only functions for verifier management
- **Stake Requirements**: Financial commitment prevents spam registrations
- **Evidence Requirements**: All reports require cryptographic evidence hashes
- **Reward Limits**: Rewards only paid for successfully blacklisted domains

## 💰 Economic Model

### Staking Mechanism
- **Registration Fee**: 10 STX per domain registration
- **Stake Pool**: Accumulated stakes fund the reward system
- **Reward Distribution**: 5% of domain stake goes to successful reporters

### Reputation System
- **Initial Score**: New domains start with 50 reputation
- **Verified Domains**: Achieve 100 reputation when verified
- **Safety Threshold**: Domains with >70 reputation and <3 reports considered safe

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm/yarn
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/shield-guard
cd shield-guard
```

2. Install dependencies:
```bash
clarinet install
```

3. Run tests:
```bash
clarinet test
```

4. Check contract syntax:
```bash
clarinet check
```

### Deployment

#### Devnet
```bash
clarinet integrate
```

#### Testnet
```bash
clarinet deploy --testnet
```

#### Mainnet
```bash
clarinet deploy --mainnet
```

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/domain-sentinel_test.ts

# Run with coverage
clarinet test --coverage
```

## 📝 Usage Examples

### Register a Domain
```clarity
(contract-call? .domain-sentinel register-domain "example.com" "sha256hashofevidence...")
```

### Check Domain Safety
```clarity
(contract-call? .domain-sentinel is-domain-safe "suspicious-site.com")
```

### Report Suspicious Domain
```clarity
(contract-call? .domain-sentinel report-suspicious-domain "phishing-site.com" "evidencehash...")
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PRs

## 📊 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Unauthorized access attempt |
| 101 | ERR-DOMAIN-EXISTS | Domain already registered |
| 102 | ERR-DOMAIN-NOT-FOUND | Domain not found in registry |
| 103 | ERR-INVALID-STATUS | Invalid status transition |
| 104 | ERR-INSUFFICIENT-STAKE | Insufficient STX for staking |
| 105 | ERR-INVALID-INPUT | Invalid input format |
| 106 | ERR-INVALID-DOMAIN | Invalid domain format |

## 🔮 Future Enhancements

- **Time-based Verification**: Automatic domain re-verification
- **Weighted Voting**: Reputation-based verifier influence
- **Browser Extension**: Real-time phishing protection
- **API Integration**: RESTful endpoints for web services
- **Cross-chain Support**: Multi-blockchain domain verification
- **Machine Learning**: AI-powered phishing detection

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language documentation and community
- Open-source security research community
- Anti-phishing organizations and initiatives

## 📞 Support

- **Documentation**: [Stacks Documentation](https://docs.stacks.co/)
- **Community**: [Stacks Discord](https://discord.gg/stacks)
- **Issues**: Create an issue on GitHub
- **Security**: Report security issues privately to security@shieldguard.io