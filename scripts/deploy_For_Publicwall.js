async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const PublicWall = await ethers.getContractFactory("PublicWall");
  const publicWall = await PublicWall.deploy();
  await publicWall.deployed();

  console.log("PublicWall deployed to:", publicWall.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
