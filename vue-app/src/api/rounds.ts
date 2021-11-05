import sdk from '@/graphql/sdk'
import { ipfsGatewayUrl, extraRounds } from './core'

export interface Round {
  index: number
  address: string
  url?: string
}
export async function getRounds(factoryAddress: string): Promise<Round[]> {
  //NOTE: why not instantiate the sdk here?
  const data = await sdk.GetRounds({
    factoryAddress: factoryAddress.toLowerCase(),
  })

  const rounds: Round[] = extraRounds.map((ipfsHash: string, index): Round => {
    return { index, address: '', url: `${ipfsGatewayUrl}/ipfs/${ipfsHash}` }
  })

  for (const fundingRound of data.fundingRounds) {
    rounds.push({
      index: rounds.length,
      address: fundingRound.id,
    })
  }
  return rounds
}
