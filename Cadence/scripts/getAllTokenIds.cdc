
import Controller from "../contracts/Controller.cdc"
pub fun main():[String]{
    return Controller.allSocialTokens.keys

}
