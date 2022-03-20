import { ethers } from 'ethers'
import { mainnetProvider } from '@/api/core'
import { isAddress } from '@ethersproject/address'
import axios from 'axios'
import { ipfsGatewayUrl } from '@/api/core'

export function isSameAddress(address1: string, address2: string): boolean {
  return ethers.utils.getAddress(address1) === ethers.utils.getAddress(address2)
}

// Looks up possible ENS for given 0x address
export async function ensLookup(address: string): Promise<string | null> {
  const name: string | null = await mainnetProvider.lookupAddress(address)
  return name
}

// Returns null if the name passed is a 0x address
// If name is valid ENS returns 0x address, else returns null
export async function resolveEns(name: string): Promise<string | null> {
  if (isAddress(name)) return null
  return await mainnetProvider.resolveName(name)
}

// Returns true if address is valid ENS or 0x address
export async function isValidEthAddress(address: string): Promise<boolean> {
  const resolved = await mainnetProvider.resolveName(address)
  return !!resolved
}

export async function getEnsAvatarUrl(address: string): Promise<string | null> {
  try {
    const name = await ensLookup(address)
    if (!name) return null
    const resolver = await mainnetProvider.getResolver(name)
    const avatar = await resolver.getText('avatar')
    const details = avatar.split('/')
    if (details.length !== 3 || details[0] !== 'eip155:1' || !details[2])
      return null
    const [, contractInfo, tokenId] = details
    const [schema, contractAddress] = contractInfo.split(':')
    const ABI =
      schema === 'erc721'
        ? [
            'function tokenURI(uint256 tokenId) external view returns (string memory)',
            'function ownerOf(uint256 tokenId) public view returns (address)',
          ]
        : [
            'function uri(uint256 _id) public view returns (string memory)',
            'function balanceOf(address account, uint256 id) public view returns (uint256)',
          ]
    const contract = new ethers.Contract(contractAddress, ABI, mainnetProvider)
    const uri =
      schema === 'erc721'
        ? await contract.tokenURI(tokenId)
        : await contract.uri(tokenId)
    const { data } = await axios.get(uri)
    return data.image
  } catch (error) {
    return null
  }
}

export async function get3BoxAvatarUrl(
  address: string
): Promise<string | null> {
  const threeBoxProfileUrl = `https://ipfs.3box.io/profile?address=${address}`
  try {
    const { data } = await axios.get(threeBoxProfileUrl)
    const profileImageHash = data.image[0].contentUrl['/']
    return `${ipfsGatewayUrl}/ipfs/${profileImageHash}`
  } catch (error) {
    return null
  }
}

export function renderAddressOrHash(
  address: string,
  digitsToShow?: number
): string {
  if (digitsToShow) {
    const beginDigits: number = Math.ceil(digitsToShow / 2)
    const endDigits: number = Math.floor(digitsToShow / 2)
    const begin: string = address.substr(0, 2 + beginDigits)
    const end: string = address.substr(address.length - endDigits, endDigits)
    return `${begin}…${end}`
  }
  return address
}
