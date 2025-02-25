// If using ES modules (recommended)
import { ethers } from "ethers"; // Add this at the top if "type": "module" in package.json

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const token0 = await MockERC20.deploy(ethers.utils.parseEther("1000")); // Use ethers.utils.parseEther
  const token1 = await MockERC20.deploy(ethers.utils.parseEther("1000"));
  await token0.waitForDeployment();
  await token1.waitForDeployment();
  console.log("Token0 deployed to:", token0.target);
  console.log("Token1 deployed to:", token1.target);

  const DEXPair = await ethers.getContractFactory("DEXPair");
  const dexPair = await DEXPair.deploy(token0.target, token1.target);
  await dexPair.waitForDeployment();
  console.log("DEXPair deployed to:", dexPair.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });