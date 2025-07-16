# Cross-Chain Rebase Token (Learning Project)

Welcome! 👋  
This repository is a **work-in-progress** as I build and experiment with a **Cross-Chain Rebase Token**. I'm actively learning smart contract security and architecture via [**Cyfrin's educational content**](https://www.cyfrin.io/) — expect frequent updates, refactoring, and experiments.

---

## 🚧 Project Status

✅ **In Development & Learning Phase**  
I’m currently focused on:

- 📈 Rebase token mechanics (similar to AMPL)
- 🌉 Cross-chain messaging research (LayerZero, Chainlink CCIP, etc.)
- 🛡️ Security patterns and vulnerabilities
- 🧪 Unit testing and fuzzing with Foundry
- 🔧 Contract modularity and extensibility

---

## 🧠 Learning Goals

This repo helps me explore and apply:

- Foundry toolkit: `forge`, `cast`, `anvil`, `Test`
- Secure contract design (pull over push, checks-effects-interactions, etc.)
- ERC20, Cross chain tokens, Chainlink CCIP
- Advanced DeFi tokenomics like rebasing and supply elasticity
- Cross-chain bridge patterns & pitfalls

---

## 🗂 Folder Structure

```bash
.
├── src/                # Core smart contracts
│   └── Rebase_Token.sol 
│   └── RebaseTokenPool.sol
│   └── Vault.sol
│   └── Interfaces 
│       └── IRebase_Token.sol       
├── script/             # Deployment and helper scripts
│ 
├── test/               # Foundry unit and integration tests
│   └── CrossChainRebase.t.sol
│   └── RebaseToken.t.sol
├── lib/                # External libraries (via forge install)
├── .env                # Environment variables (RPCs, private keys)
├── foundry.toml        # Foundry configuration
└── README.md
└── remappings.txt
