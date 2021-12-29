// This script reads the supply of social token

import SocialToken from 0xf8d6e0586b0a20c7

pub fun main(): UFix64 {
    return SocialToken.totalSupply
}