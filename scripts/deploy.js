const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    let NFT;
    let StakeSystem;
    let Coin;

    NFT = await hre.ethers.getContractFactory(
        "NFT"
    );
    Coin = await hre.ethers.getContractFactory("Coin");
    StakeSystem = await hre.ethers.getContractFactory("StakeSystem");

    NFT = await NFT.deploy(
        "https://test-api.com/",
        "https://test-api.com/"
    );
    Coin = await Coin.deploy();
    StakeSystem = await StakeSystem.deploy(
        NFT.address,
        Coin.address
    );

    await NFT.deployed();
    console.log("NFT deployed to:", NFT.address);
    await Coin.deployed();
    console.log("Coin deployed to:", Coin.address);
    await StakeSystem.deployed();
    console.log("StakeSystem deployed to:", StakeSystem.address);

    await Coin.addController(StakeSystem.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
