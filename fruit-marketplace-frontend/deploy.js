// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const FruitMarketplace = await ethers.getContractFactory("FruitMarketplace");
  const marketplace = await FruitMarketplace.deploy();

  console.log("FruitMarketplace deployed to:", marketplace.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
