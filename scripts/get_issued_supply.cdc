
import Controller from 0xf8d6e0586b0a20c7

pub fun main(name: String): UFix64 {
  return Controller.getTokenDetails(name).issuedSupply
}