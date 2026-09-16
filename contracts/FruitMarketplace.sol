// SPDX-License-Identifier: MIT 
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
pragma solidity ^0.8.20;

contract FruitMarketplace is ReentrancyGuard {
    struct Fruit {
        uint fruitId; // Identifiant unique du fruit
        uint price; // en wei
        address payable seller; // Adresse du vendeur payable pour recevoir des fonds
        address buyer; // Adresse de l'acheteur
        string name; // Nom du fruit // bool isSold; // Indique si le fruit a été vendu (remplacé par isAvailable)
        bool isAvailable; // Indique si le fruit est disponible à la vente
    }

    uint public fruitCount = 0;  // Compteur de fruits disponibles sur le marché
    mapping(uint => Fruit) public fruits; // Mapping pour stocker les fruits par ID

    // Évaluations des vendeurs (note * 10 pour éviter les décimales)
    mapping(address => uint256) public sellerRatings; // Compteur d'évaluations pour chaque vendeur
    mapping(address => uint256) public sellerRatingsCount; // Nombre d'évaluations pour chaque vendeur

    // Événements
    event FruitListed(uint256 indexed fruitId, string name, uint256 price, address indexed seller); // Événement émis lors de la mise en vente d'un fruit par un vendeur
    event FruitPurchased(uint256 indexed fruitId, address indexed buyer, uint256 price); // Événement émis lors de l'achat d'un fruit
    event FruitUpdated(uint256 indexed fruitId, uint256 newPrice); // Événement émis lors de la mise à jour du prix d'un fruit par le vendeur (seulement lui peut le faire d'ou l'absence de l'indexé)
    event FruitRemoved(uint256 indexed fruitId, address indexed seller); // Événement émis lors de la suppression d'un fruit par le vendeur
    event SellerRated(address indexed seller, address rater, uint256 rating); // Événement émis lors de l'évaluation d'un vendeur par un acheteur
    event ExcessAmountRefunded(address indexed buyer, uint256 amount); // Événement émis lors du remboursement d'un excédent d'argent à l'acheteur
    

    // Vérifier si l'appelant est le vendeur du fruit
    modifier onlySeller(uint256 _fruitId) {
        require(_fruitId < fruitCount, "Le fruit n'existe pas");
        require(msg.sender == fruits[_fruitId].seller, "N'est pas le vendeur du fruit");
        _;
    }

    // Vérifier si le fruit est disponible
    modifier fruitAvailable(uint256 _fruitId) {
        require(fruits[_fruitId].isAvailable, "Le fruit n'est pas disponible");
        _;
    }

    // Ajouter un fruit au marché
    function listFruit(string memory _name, uint256 _price) public {
        require(_price > 0, "Le prix doit etre superieur a 0");
        require(bytes(_name).length > 0, "Le nom du fruit ne peut pas etre vide");

        fruits[fruitCount] = Fruit({
            fruitId: fruitCount,
            price: _price,
            seller: payable(msg.sender),
            buyer: address(0),
            name: _name,
            isAvailable: true
        });

        emit FruitListed(fruitCount, _name, _price, msg.sender);
        fruitCount++;
    }

    // Acheter un fruit (avec remboursement de l'excédent)
    function buyFruit(uint256 _id) public payable {
        require(_id < fruitCount, "Le fruit n'existe pas");
        Fruit storage fruit = fruits[_id];

        require(fruit.isAvailable, "Le fruit n'est pas disponible");
        require(msg.value >= fruit.price, "Fonds insuffisants pour acheter le fruit");
        require(fruit.seller != msg.sender, "Le vendeur ne peut pas acheter son propre fruit");

        // Effects avant interactions
        fruit.isAvailable = false;
        fruit.buyer = msg.sender;

        // Transfert au vendeur
        (bool success1, ) = fruit.seller.call{value: fruit.price}("");
        require(success1, "Le transfert a echoue");

        // Remboursement de l'excédent
        uint256 excess = msg.value - fruit.price;
        if (excess > 0) {
            (bool success2, ) = msg.sender.call{value: excess}("");
            require(success2, "Remboursement echoue");
            emit ExcessAmountRefunded(msg.sender, excess);
        }

        emit FruitPurchased(_id, msg.sender, fruit.price);
    }

    // Mettre à jour le prix
    function updateFruitPrice(uint256 _id, uint256 _newPrice) public onlySeller(_id) fruitAvailable(_id) {
        require(_newPrice > 0, "Prix doit etre superieur a 0");
        fruits[_id].price = _newPrice;
        emit FruitUpdated(_id, _newPrice);
    }

    // Retirer un fruit du marché
    function removeFruit(uint256 _id) public onlySeller(_id) fruitAvailable(_id) {
        fruits[_id].isAvailable = false;
        emit FruitRemoved(_id, msg.sender);
    }

    // Évaluer un vendeur (note de 1 à 5, stockée x10 pour éviter les décimales)
    function rateSeller(address _seller, uint256 _rating) public {
        require(_rating >= 1 && _rating <= 5, "La note doit etre comprise entre 1 et 5");
        require(_seller != msg.sender, "Le vendeur ne peut pas s'auto-evaluer");

        sellerRatings[_seller] += _rating * 10;
        sellerRatingsCount[_seller]++;

        emit SellerRated(_seller, msg.sender, _rating);
    }

    // Obtenir la note moyenne (divisée par 10)
    function getSellerAverageRating(address _seller) public view returns (uint256) {
        if (sellerRatingsCount[_seller] == 0) return 0;
        return sellerRatings[_seller] / sellerRatingsCount[_seller];
    }

    // Fonction utilitaire pour récupérer un fruit
    function getFruit(uint256 _fruitId) public view returns (
        uint256 fruitId,
        string memory name,
        uint256 price,
        address seller,
        address buyer,
        bool isAvailable
    ) {
        require(_fruitId < fruitCount, "Le fruit n'existe pas");
        Fruit memory fruit = fruits[_fruitId]; // Récupérer le fruit à partir du mapping
        return (
            fruit.fruitId,
            fruit.name,
            fruit.price,
            fruit.seller,
            fruit.buyer,
            fruit.isAvailable
        );
    }
}
