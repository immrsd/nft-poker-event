import { ethers } from "hardhat";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { Tournament__factory } from "../typechain/factories/contracts/Tournament__factory";
import { Tournament } from "../typechain/contracts/Tournament";
import { BigNumber, Wallet } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MerkleTree } from 'merkletreejs';
import { randomBytes } from 'crypto';

chai.use(solidity);
const { expect } = chai;

const parseEther = ethers.utils.parseEther;
const keccak256 = ethers.utils.keccak256;

const Defaults = {
  fee: parseEther("0.02"),
  rake: 10,
  seedCheckhash: keccak256(ethers.utils.id("Poker Tournament")),
  duration: 21 * 24 * 60 * 60,
  maxEntries: 50
}

async function deployContract(
  deployer: SignerWithAddress,
  merkleRoot: string,
  fee: BigNumber = Defaults.fee, 
  rake: number = Defaults.rake, 
  hash: string = Defaults.seedCheckhash
): Promise<string> {

  const instance = await new Tournament__factory(deployer).deploy(fee, rake, hash, merkleRoot);
  return instance.address;
}

type MerkleSetup = {
  tree: MerkleTree,
  users: string[]
}

function prepareMerkleTree(deployer: string): MerkleSetup {
  const users = new Array(15)
    .fill(0)
    .map(_ => new Wallet(randomBytes(32).toString("hex")).address)
    .concat(deployer)

  const tree = new MerkleTree(
    users, 
    keccak256, 
    { hashLeaves: true, sortPairs: true }
  )
  return { tree, users }
}

describe("Token", () => {

  describe("Check initial state", async () => {

    let contract: Tournament

    beforeEach(async () => {
      const [deployer, user] = await ethers.getSigners()
      const merkleSetup = prepareMerkleTree(deployer.address)
      const address = await deployContract(deployer, merkleSetup.tree.getHexRoot())
      contract = new Tournament__factory(user).attach(address)
    })

    it("Should has correct init parameters", async () => {
      expect(await contract.ENTRANCE_FEE()).to.be.equal(Defaults.fee, "Wrong fee value")
      expect(await contract.RAKE_PERCENTAGE()).to.be.equal(Defaults.rake, "Wrong rake value")
      expect(await contract.SEED_CHECKHASH()).to.be.equal(Defaults.seedCheckhash, "Wrong checkhash value")

      // Check constants
    })

    it("Should has correct constants", async () => {
      expect(await contract.TOURNAMENT_DURATION()).to.be.equal(Defaults.duration, "Wrong duration")
      expect(await contract.MAX_ENTRIES_PER_PLAYER()).to.be.equal(Defaults.maxEntries, "Wrong max entries")
    })
  })

  describe("Check whitelist logic", async () => {
    
    let contract: Tournament
    let merkleSetup: MerkleSetup

    beforeEach(async () => {
      const [deployer, user] = await ethers.getSigners()
      merkleSetup = prepareMerkleTree(deployer.address)
      const address = await deployContract(deployer, merkleSetup.tree.getHexRoot())
      contract = new Tournament__factory(user).attach(address)
    })

    it("Should allow whitelisted users", async () => {
      merkleSetup.users.forEach(async user => {
        const proof = merkleSetup.tree.getHexProof(keccak256(user))
        expect(proof).to.not.eq([])
        expect(await contract.isEligible(user, proof)).to.eq(true)
      })
    })
  })
});
