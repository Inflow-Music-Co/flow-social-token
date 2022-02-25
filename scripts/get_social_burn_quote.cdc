// This script reads the mintQuote field of Admin's Minter Resource

import SocialToken from 0x1cf0e2f2f715450

pub fun main(amount: UFix64, tokenId: String):UFix64{

    return SocialToken.getBurnPrice(tokenId, amount)

}