import { ethers } from "hardhat";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { Tournament__factory } from "../typechain";

chai.use(solidity);
const { expect } = chai;

describe("Token", () => {
  let tournamentAddress: string;

  beforeEach(async () => {
    const [deployer] = await ethers.getSigners();
    const factory = new Tournament__factory(deployer);
    const instance = await factory.deploy();
    tournamentAddress = instance.address;

    expect(await instance.totalSupply()).to.eq(0);
  });

  describe("Enroll", async () => {
    it("", async () => {
      const [deployer, user] = await ethers.getSigners();
      const instance = new Tournament__factory(user).attach(tournamentAddress);

      await instance.enroll();
    });
  });
});
