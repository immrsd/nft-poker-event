import { ethers } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';

async function main(): Promise<void> {
  const contractName = 'Tournament';
  const factory: ContractFactory = await ethers.getContractFactory(contractName);
  const tournament: Contract = await factory.deploy();
  await tournament.deployed();
  console.log(`${contractName} deployed to ${tournament.address}!`);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
