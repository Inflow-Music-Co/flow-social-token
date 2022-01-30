
import Controller from "../contracts/Controller.cdc"
pub fun main(name:String): Controller.TokenStructure? {
  return Controller.allSocialTokens[name]
}
