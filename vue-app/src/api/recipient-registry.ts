import { BigNumber } from 'ethers'

import { recipientRegistryType } from './core'
import OptimisticRegistry from './recipient-registry-optimistic'
import PessimisticRegistry from './recipient-registry-pessimistic'

export interface RegistryInfo {
  deposit: BigNumber
  depositToken: string
  listingPolicyUrl: string
  recipientCount: number
  owner: string
}

export interface RecipientApplicationData {
  project: {
    name: string
    tagline: string
    description: string
    category: string
    problemSpace: string
  }
  fund: {
    addressName: string
    resolvedAddress: string
    plans: string
  }
  team: {
    name: string
    description: string
    email: string
  }
  links: {
    github: string
    radicle: string
    website: string
    twitter: string
    discord: string
  }
  image: {
    bannerHash: string
    thumbnailHash: string
  }
  furthestStep: number
  hasEns: boolean
}

export async function getRegistryInfo(
  registryAddress: string
): Promise<RegistryInfo> {
  if (recipientRegistryType === 'optimistic') {
    return OptimisticRegistry.getRegistryInfo(registryAddress)
  } else if (recipientRegistryType === 'pessimistic') {
    return PessimisticRegistry.getRegistryInfo(registryAddress)
  } else {
    throw new Error('invalid recipient registry type')
  }
}
