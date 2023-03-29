# My NFT Project

This project includes an ERC721 token (PeakyBirds), an auction house contract (AuctionHouse), and an authority contract (ERC721Authority) to manage token minting and transfer permissions.

## Prerequisites

- Node.js (v12.x or higher)
- npm (v6.x or higher)
- Truffle (v5.x or higher)
- An Ethereum wallet with some Ether (e.g., MetaMask)

## Getting Started

1. Clone the repository and navigate to the project folder:

git clone https://github.com/yourusername/my-nft-project.git
cd my-nft-project

2. Install the dependencies:

npm install

3. Set up the environment variables:

Copy the `.env.example` file to a new `.env` file and replace the placeholders with your Infura Project ID and Ethereum wallet private key.

cp .env.example .env

4. Compile the contracts:

trufle compile

5. Deploy the contracts to the desired Ethereum network:

truffle migrate --network rinkeby

Replace `rinkeby` with the network you wish to deploy to.

## Contracts

- `PeakyBirds`: An ERC721 token contract with minting and transfer permissions managed by the ERC721Authority contract.
- `ERC721Authority`: Manages minting and transfer permissions for the MyERC721 contract. It has a whitelist for the AuctionHouse contract and another whitelist for regular users. Minting can be enabled/disabled for regular users.
- `AuctionHouse`: A contract that allows users to create auctions for their ERC721 tokens. The auction starts automatically, and a new auction begins once the previous auction ends and a new token is received. The highest bidder can claim the token at the end of the auction.

## License

This project is licensed under the MIT License.


