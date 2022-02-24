import fs from 'fs'
import { ethers } from 'hardhat'
import { BigNumber, Wallet } from 'ethers'
import { PrivKey, Keypair } from 'maci-domainobjs'

import { createMessage } from '../utils/maci'

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
  const coordinatorKeyPair = new Keypair(
    PrivKey.unserialize(state.coordinatorPrivKey)
  )

  for (const contributor of [
    contributor1,
    contributor2,
    contributor3,
    contributor4,
  ]) {
    const contributorAddress = await contributor.getAddress()
    const contributorData = state.contributors[contributorAddress]
    const contributorKeyPair = new Keypair(
      PrivKey.unserialize(contributorData.privKey)
    )
    const messages = []
    const encPubKeys = []
    let nonce = 1
    // Change key
    const newContributorKeypair = new Keypair()
    const [message, encPubKey] = createMessage(
      contributorData.stateIndex,
      contributorKeyPair,
      newContributorKeypair,
      coordinatorKeyPair.pubKey,
      null,
      null,
      nonce
    )
    messages.push(message.asContractParam())
    encPubKeys.push(encPubKey.asContractParam())
    nonce += 1
    // Vote
    const recipients = [1, 2, 3, 4, 5, 6, 7]
    for (const recipientIndex of recipients) {
      const votes = BigNumber.from(contributorData.voiceCredits).div(
        recipients.length
      )
      const [message, encPubKey] = createMessage(
        contributorData.stateIndex,
        newContributorKeypair,
        null,
        coordinatorKeyPair.pubKey,
        recipientIndex,
        votes,
        nonce
      )
      messages.push(message.asContractParam())
      encPubKeys.push(encPubKey.asContractParam())
      nonce += 1
    }

    const fundingRoundAsContributor = await ethers.getContractAt(
      'FundingRound',
      state.fundingRound,
      contributor
    )

    const tx = await fundingRoundAsContributor.submitMessageBatch(
      messages.reverse(),
      encPubKeys.reverse(),
      {
        gasLimit: 20000000,
      }
    )
    try {
      await tx.wait()
    } catch (err) {
      console.log('error!', err)
      return
    }

    console.log(`Contributor ${contributorAddress} voted.`)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
