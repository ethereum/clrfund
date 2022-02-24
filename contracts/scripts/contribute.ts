import fs from 'fs'
import { Wallet } from 'ethers'
import { ethers } from 'hardhat'
import { Keypair } from 'maci-domainobjs'

import { UNIT } from '../utils/constants'
import { getEventArg } from '../utils/contracts'

async function main() {
  // const [, , , , , , , , , , , , contributor1, contributor2, contributor3] =
  //   await ethers.getSigners()

  const contributor1 = new Wallet(
    process.env.CONTRIBUTOR_PK_1!,
    ethers.provider
  )
  const contributor2 = new Wallet(
    process.env.CONTRIBUTOR_PK_2!,
    ethers.provider
  )
  const contributor3 = new Wallet(
    process.env.CONTRIBUTOR_PK_3!,
    ethers.provider
  )
  const contributor4 = new Wallet(
    process.env.CONTRIBUTOR_PK_4!,
    ethers.provider
  )

  const state = JSON.parse(fs.readFileSync('state.json').toString())
  const fundingRound = await ethers.getContractAt(
    'FundingRound',
    state.fundingRound
  )
  const tokenAddress = await fundingRound.nativeToken()
  const token = await ethers.getContractAt('AnyOldERC20Token', tokenAddress)
  const maciAddress = await fundingRound.maci()
  const maci = await ethers.getContractAt('MACI', maciAddress)

  const contributionAmount = UNIT.mul(16).div(10)
  state.contributors = {}

  for (const contributor of [
    contributor1,
    contributor2,
    contributor3,
    contributor4,
  ]) {
    const contributorAddress = await contributor.getAddress()
    const contributorKeypair = new Keypair()
    const tokenAsContributor = token.connect(contributor)
    await tokenAsContributor.approve(fundingRound.address, contributionAmount)
    const fundingRoundAsContributor = fundingRound.connect(contributor)
    const contributionTx = await fundingRoundAsContributor.contribute(
      contributorKeypair.pubKey.asContractParam(),
      contributionAmount
    )
    const stateIndex = await getEventArg(
      contributionTx,
      maci,
      'SignUp',
      '_stateIndex'
    )
    const voiceCredits = await getEventArg(
      contributionTx,
      maci,
      'SignUp',
      '_voiceCreditBalance'
    )
    state.contributors[contributorAddress] = {
      privKey: contributorKeypair.privKey.serialize(),
      pubKey: contributorKeypair.pubKey.serialize(),
      stateIndex: parseInt(stateIndex),
      voiceCredits: voiceCredits.toString(),
    }
    console.log(
      `Contributor ${contributorAddress} registered. State index: ${stateIndex}. Voice credits: ${voiceCredits.toString()}.`
    )
  }

  // Update state file
  fs.writeFileSync('state.json', JSON.stringify(state))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
