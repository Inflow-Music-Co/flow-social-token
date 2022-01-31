// This script reads the mintQuote field of Admin's Minter Resource

import SocialToken from 0xf8d6e0586b0a20c7

pub fun main(amount: UFix64, tokenId: String):UFix64{

    return  SocialToken.getMintPrice(tokenId, amount)
}