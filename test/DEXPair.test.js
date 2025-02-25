// test/DEXPair.test.js
const { expect } = require("chai");

describe("DEXPair", function () {
    let token0, token1, dexPair, owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();

        const MockERC20 = await ethers.getContractFactory("MockERC20");
        token0 = await MockERC20.deploy(ethers.parseEther("1000"));
        token1 = await MockERC20.deploy(ethers.parseEther("1000"));
        await token0.waitForDeployment();
        await token1.waitForDeployment();

        const DEXPair = await ethers.getContractFactory("DEXPair");
        dexPair = await DEXPair.deploy(token0.target, token1.target);
        await dexPair.waitForDeployment();
    });

    it("should allow adding liquidity", async function () {
        await token0.approve(dexPair.target, ethers.parseEther("100"));
        await token1.approve(dexPair.target, ethers.parseEther("100"));
        // Add your contract's addLiquidity function call here
        // Example: await dexPair.addLiquidity(ethers.parseEther("100"), ethers.parseEther("100"));
        // Add assertions to check reserves or liquidity tokens
    });

    it("should perform a swap", async function () {
        // Add test for token swap functionality
    });
});
