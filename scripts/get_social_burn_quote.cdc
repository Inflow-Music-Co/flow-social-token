// This script reads the mintQuote field of Admin's Minter Resource

import Controller from "../contracts/Controller.cdc"

pub fun main(amount: UFix64, tokenId: String):UFix64{

    return Controller.getBurnPrice(tokenId, amount)

}