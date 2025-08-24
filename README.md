# CivicVote

**A decentralized voting system for municipal and local government elections on the Stacks blockchain**

CivicVote is a secure, transparent smart contract that enables democratic voting for local elections with support for multiple simultaneous elections, candidate management, and real-time result tracking.

## 🌟 Features

- **Multi-Election Support**: Create and manage multiple simultaneous elections
- **Secure Voting**: One vote per participant with cryptographic verification
- **Transparent Results**: Real-time vote counting and public result visibility
- **Candidate Management**: Dynamic candidate registration before election start
- **Time-Based Elections**: Block-height based election scheduling and automatic expiration
- **Authorization Controls**: Election creator permissions for candidate management
- **Vote Privacy**: Anonymous voting with participation tracking
- **Immutable Records**: All votes and election data stored permanently on-chain

## 🏗️ Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0
- **Testing Framework**: Clarinet SDK with Vitest

## 📦 Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v14 or higher)
- [Git](https://git-scm.com/)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd CivicVote
   ```

2. **Navigate to the contract directory**
   ```bash
   cd CivicVote_contract
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Verify installation**
   ```bash
   clarinet check
   ```

## 🚀 Usage Examples

### Creating an Election

```clarity
;; Create a new election lasting 1000 blocks (~1 week)
(contract-call? .CivicVote create-election 
    "Mayor Election 2024" 
    "Vote for your preferred candidate for Mayor" 
    u1000)
```

### Adding Candidates

```clarity
;; Add candidates to election ID 1 (only election creator can do this)
(contract-call? .CivicVote add-candidate u1 "Alice Johnson" "Experienced city planner")
(contract-call? .CivicVote add-candidate u1 "Bob Smith" "Local business owner")
(contract-call? .CivicVote add-candidate u1 "Carol Davis" "Former city council member")
```

### Casting a Vote

```clarity
;; Vote for candidate 0 in election 1
(contract-call? .CivicVote cast-vote u1 u0)
```

### Checking Results

```clarity
;; Get election details and results
(contract-call? .CivicVote get-election u1)
(contract-call? .CivicVote get-candidate u1 u0)
```

## 📋 Contract Functions

### Public Functions

#### `create-election`
Creates a new election with specified duration.
- **Parameters**: `title` (string), `description` (string), `duration-blocks` (uint)
- **Returns**: Election ID
- **Access**: Any user

#### `add-candidate`
Adds a candidate to an existing election.
- **Parameters**: `election-id` (uint), `name` (string), `description` (string)
- **Returns**: Candidate ID
- **Access**: Election creator only, before election starts

#### `cast-vote`
Casts a vote for a candidate in an active election.
- **Parameters**: `election-id` (uint), `candidate-id` (uint)
- **Returns**: Success boolean
- **Access**: Any user (one vote per election)

#### `end-election`
Ends an election before its scheduled end time.
- **Parameters**: `election-id` (uint)
- **Returns**: Success boolean
- **Access**: Election creator or anyone after end-block

### Read-Only Functions

#### `get-election`
Retrieves election details including vote counts.
- **Parameters**: `election-id` (uint)
- **Returns**: Election data or none

#### `get-candidate`
Retrieves candidate information and vote count.
- **Parameters**: `election-id` (uint), `candidate-id` (uint)
- **Returns**: Candidate data or none

#### `get-vote`
Gets voting details for a specific voter.
- **Parameters**: `election-id` (uint), `voter` (principal)
- **Returns**: Vote data or none

#### `has-voter-participated`
Checks if a voter has already voted in an election.
- **Parameters**: `election-id` (uint), `voter` (principal)
- **Returns**: Boolean

#### `get-candidate-count`
Returns the number of candidates in an election.
- **Parameters**: `election-id` (uint)
- **Returns**: Candidate count

#### `is-election-active`
Checks if an election is currently accepting votes.
- **Parameters**: `election-id` (uint)
- **Returns**: Boolean

#### `get-current-block`
Returns the current block height.
- **Returns**: Current block height

## 🧪 Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage and cost analysis:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## 🚀 Deployment

### Local Development (Devnet)

1. **Start Clarinet console**
   ```bash
   clarinet console
   ```

2. **Deploy the contract**
   ```clarity
   (contract-call? 'ST000000000000000000002AMW42H.CivicVote create-election "Test Election" "Test Description" u100)
   ```

### Testnet Deployment

1. **Configure testnet settings**
   Edit `settings/Testnet.toml` with your deployment parameters.

2. **Deploy to testnet**
   ```bash
   clarinet deployments generate --testnet
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment

1. **Configure mainnet settings**
   Edit `settings/Mainnet.toml` with production parameters.

2. **Deploy to mainnet** (Use with caution)
   ```bash
   clarinet deployments generate --mainnet
   clarinet deployments apply --mainnet
   ```

## 🔒 Security Considerations

### Access Control
- Election creators have exclusive rights to add candidates before election start
- Only one vote per participant per election is allowed
- Elections automatically expire based on block height

### Data Integrity
- All election data is immutable once created
- Vote counts are automatically updated and cannot be manually altered
- Voter participation is tracked to prevent double voting

### Time-Based Security
- Elections have defined start and end blocks
- Voting is only allowed during the active period
- Early termination requires creator authorization

### Error Handling
The contract includes comprehensive error codes:
- `ERR_UNAUTHORIZED (u1)`: Insufficient permissions
- `ERR_ELECTION_NOT_FOUND (u2)`: Invalid election ID
- `ERR_ELECTION_NOT_ACTIVE (u3)`: Election not accepting votes
- `ERR_ALREADY_VOTED (u4)`: Voter has already participated
- `ERR_CANDIDATE_NOT_FOUND (u5)`: Invalid candidate ID
- `ERR_ELECTION_ALREADY_ENDED (u6)`: Election has concluded
- `ERR_ELECTION_ALREADY_STARTED (u7)`: Cannot modify started election
- `ERR_INVALID_PARAMETERS (u8)`: Invalid input parameters

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and add tests
4. Run the test suite: `npm test`
5. Commit your changes: `git commit -am 'Add new feature'`
6. Push to the branch: `git push origin feature/new-feature`
7. Submit a pull request

## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details.

## 🔗 Resources

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [Stacks Blockchain](https://www.stacks.co/)

## 📞 Support

For questions, issues, or contributions, please:
- Open an issue on GitHub
- Contact the development team
- Refer to the Stacks community resources

---

**CivicVote** - Empowering democratic participation through blockchain technology