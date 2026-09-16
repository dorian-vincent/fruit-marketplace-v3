const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FruitMarketplace", function () {
  let FruitMarketplace, marketplace, owner, seller, buyer;

  beforeEach(async function () {
    // Obtenir les signers pour les tests
    [owner, seller, buyer] = await ethers.getSigners();

    // Déployer le contrat avant chaque test
    FruitMarketplace = await ethers.getContractFactory("FruitMarketplace");
    marketplace = await FruitMarketplace.deploy();
    await marketplace.waitForDeployment();
    console.log("Contract deployed at:", await marketplace.getAddress());
  });

  it("doit déployer correctement le contrat", async function () {
    expect(await marketplace.getAddress()).to.not.equal("0x0000000000000000000000000000000000000000");
  });

  it("doit ajouter un fruit avec les bons détails", async function () {
    await marketplace.connect(seller).listFruit("Banane", ethers.parseEther("1"));
    const fruit = await marketplace.getFruit(0);

    expect(fruit.name).to.equal("Banane");
    expect(fruit.price).to.equal(ethers.parseEther("1"));
    expect(fruit.seller).to.equal(seller.address);
    expect(fruit.isAvailable).to.be.true;
  });

  it("doit permettre d’acheter un fruit et enregistrer l’acheteur", async function () {
    await marketplace.connect(seller).listFruit("Mangue", ethers.parseEther("1"));
    await marketplace.connect(buyer).buyFruit(0, { value: ethers.parseEther("1") });
    const fruit = await marketplace.getFruit(0);

    expect(fruit.buyer).to.equal(buyer.address);
    expect(fruit.isAvailable).to.be.false;
  });

  it("doit rendre le fruit indisponible après achat", async function () {
    await marketplace.connect(seller).listFruit("Pomme", ethers.parseEther("1"));
    await marketplace.connect(buyer).buyFruit(0, { value: ethers.parseEther("1") });
    const fruit = await marketplace.getFruit(0);

    expect(fruit.isAvailable).to.be.false;
  });

  it("doit permettre d’évaluer un fournisseur", async function () {
    await marketplace.connect(seller).listFruit("Orange", ethers.parseEther("1"));
    await marketplace.connect(buyer).rateSeller(seller.address, 5);

    const averageRating = await marketplace.getSellerAverageRating(seller.address);
    expect(averageRating).to.equal(50); // 5 * 10
  });

  it("doit permettre de mettre à jour les détails du fruit", async function () {
    await marketplace.connect(seller).listFruit("Poire", ethers.parseEther("1"));
    await marketplace.connect(seller).updateFruitPrice(0, ethers.parseEther("2"));
    const fruit = await marketplace.getFruit(0);

    expect(fruit.price).to.equal(ethers.parseEther("2"));
  });

  it("ne doit pas permettre l’achat avec des fonds insuffisants", async function () {
    await marketplace.connect(seller).listFruit("Fraise", ethers.parseEther("1"));
    await expect(
      marketplace.connect(buyer).buyFruit(0, { value: ethers.parseEther("0.5") })
    ).to.be.revertedWith("Fonds insuffisants pour acheter le fruit");

    const fruit = await marketplace.getFruit(0);
    expect(fruit.isAvailable).to.be.true;
  });
});

