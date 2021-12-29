// This script reads the mintQuote field of Admin's Minter Resource

import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7

pub fun main(amount: UFix64): UFix64 {
    return SocialToken.getBurnPrice(amount: amount)
}