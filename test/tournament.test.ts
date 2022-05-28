import { ethers } from "hardhat";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { Tournament__factory } from "../typechain";
import { BigNumber } from "ethers";
import { assert } from "console";

chai.use(solidity);
const { expect } = chai;

const parseEther = ethers.utils.parseEther;
const keccak256 = ethers.utils.keccak256;

const Defaults = {
  fee: parseEther("0.02"),
  rake: 10,
  seedCheckhash: keccak256(keccak256("Poker Tournament")),
  duration: 21 * 24 * 60 * 60,
  maxEntries: 50
}

const deployContract = async (
  fee: BigNumber = Defaults.fee, 
  rake: number = Defaults.rake, 
  hash: string = Defaults.seedCheckhash
): Promise<string> => {

  const [deployer] = await ethers.getSigners();
  const factory = new Tournament__factory(deployer);
  const instance = await factory.deploy(fee, rake, hash);
  return instance.address;
}

describe("Token", () => {

  describe("Check initial state", async () => {
    const address = await deployContract();
    const [, user] = await ethers.getSigners();
    const userInstance = new Tournament__factory(user).attach(address);

    it("Should has correct init parameters", async () => {
      expect(await userInstance.ENTRANCE_FEE()).to.be.equal(Defaults.fee, "Wrong fee value");
      expect(await userInstance.RAKE_PERCENTAGE()).to.be.equal(Defaults.rake, "Wrong rake value");
      expect(await userInstance.SEED_CHECKHASH()).to.be.equal(Defaults.seedCheckhash, "Wrong checkhash value");
    });

    it("Should has correct constants", async () => {
      expect(await userInstance.TOURNAMENT_DURATION()).to.be.equal(Defaults.duration, "Wrong duration");
      expect(await userInstance.MAX_ENTRIES_PER_PLAYER()).to.be.equal(Defaults.maxEntries, "Wrong max entries");
    });
  });
});
