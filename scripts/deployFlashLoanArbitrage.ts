import { ethers } from "hardhat";

async function main() {
    const [signer] = await ethers.getSigners();

    const flashLoanArbitrage = await ethers.deployContract("FlashLoanArbitrage",
        [
            process.env.AAVE_POOL_ADDRESSES_PROVIDER,
            process.env.DEX_AGGREGATOR,
            ethers.BigNumber.from(process.env.PROTOCOL_FEE)
        ],
        { signer }
    );

    await flashLoanArbitrage.waitForDeployment();

    console.log(`FlashLoanArbitrage contract successfully deployed on ${flashLoanArbitrage.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});