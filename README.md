# Fruit Marketplace
 
Smart contract Solidity et frontend web pour une marketplace décentralisée : mise en vente, achat et évaluation de vendeurs, avec paiement en ETH.
 
## Stack
 
- Solidity 0.8.20, protection contre la réentrance via OpenZeppelin (ReentrancyGuard)
- Hardhat pour la compilation, le déploiement et les tests
- JavaScript (ethers.js) pour l'interaction frontend avec le contrat
 
## Fonctionnalités du contrat
 
- Mise en vente d'un article avec prix en wei
- Achat sécurisé (protection contre la réentrance, remboursement de l'excédent envoyé)
- Mise à jour de prix et retrait d'article réservés au vendeur
- Système de notation des vendeurs
 
## Lancer
 
npm install
npx hardhat test
npx hardhat run scripts/deploy.js
 
## Ce que ça démontre
 
Écriture d'un smart contract sécurisé (protection contre la réentrance, contrôle d'accès par modificateurs) et tests end-to-end avec Hardhat.
