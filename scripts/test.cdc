// test script to ensure code is running
import FungibleToken from 0xee82856bf20e2aa6

pub fun main(account: Address): String {
    return getAccount(account).address.toString()
}
