import makeBlockie from 'ethereum-blockies-base64'
import { BigNumber, Contract } from 'ethers'
import { Web3Provider } from '@ethersproject/providers'

import { UserRegistry, ERC20 } from './abi'
import { factory, provider } from './core'
import { BrightId } from './bright-id'
import { get3BoxAvatarUrl, getEnsAvatarUrl } from '../utils/accounts'

//TODO: update anywhere this is called to take factory address as a parameter, default to env. variable
export const LOGIN_MESSAGE = `Welcome to clr.fund!

To get logged in, sign this message to prove you have access to this wallet. This does not cost any ether.

You will be asked to sign each time you load the app.

Contract address: ${factory.address.toLowerCase()}.`

export interface User {
  walletAddress: string
  walletProvider: Web3Provider
  encryptionKey: string
  brightId?: BrightId
  isRegistered: boolean // If is in user registry
  balance?: BigNumber | null
  etherBalance?: BigNumber | null
  contribution?: BigNumber | null
  ensName?: string | null
}

export async function getProfileImageUrl(
  walletAddress: string
): Promise<string | null> {
  // Priority to ENS avatars
  const ensAvatarUrl: string | null = await getEnsAvatarUrl(walletAddress)
  if (ensAvatarUrl) return ensAvatarUrl

  // Then to 3Box
  const threeBoxAvatarUrl: string | null = await get3BoxAvatarUrl(walletAddress)
  if (threeBoxAvatarUrl) return threeBoxAvatarUrl

  // Blockies as a fallback
  return makeBlockie(walletAddress)
}

export async function isVerifiedUser(
  userRegistryAddress: string,
  walletAddress: string
): Promise<boolean> {
  const registry = new Contract(userRegistryAddress, UserRegistry, provider)
  return await registry.isVerifiedUser(walletAddress)
}

export async function getTokenBalance(
  tokenAddress: string,
  walletAddress: string
): Promise<BigNumber> {
  const token = new Contract(tokenAddress, ERC20, provider)
  return await token.balanceOf(walletAddress)
}

export async function getEtherBalance(
  walletAddress: string
): Promise<BigNumber> {
  return await provider.getBalance(walletAddress)
}
