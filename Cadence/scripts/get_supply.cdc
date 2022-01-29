import SocialToken from "../contracts/SocialToken.cdc"
pub fun main(): UFix64 {
    return SocialToken.totalSupply
}
