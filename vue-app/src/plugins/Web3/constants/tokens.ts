export interface Token {
  logo: string
}

// Can lookup token information by passing
// TOKEN_INFO[nativeTokenSymbol.toUpperCase()]
export const TOKEN_INFO: { [key: string]: Token } = {
  ETH: {
    logo: 'eth.svg',
  },
  DAI: {
    logo: 'dai.svg',
  },
  WXDAI: {
    logo: 'wxdai.svg',
  },
  USDC: {
    logo: 'usdc.svg',
  },
  WETH: {
    logo: 'weth.svg',
  },
  AOE: {
    logo: 'aoe.svg',
  },
  MATIC: {
    logo: 'matic.svg',
  },
}

export const DEFAULT_TOKEN = {
  nativeTokenAddress: '0xda10009cbd5d07dd0cecc66161fc93d7c9000da1',
  nativeTokenSymbol: 'DAI',
  nativeTokenDecimals: 18,
}
