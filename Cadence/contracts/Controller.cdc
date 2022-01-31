import FungibleToken from 0xee82856bf20e2aa6

pub contract Controller {

    pub var allSocialTokens : {String: TokenStructure}
    pub var allArtist : {Address: Artist}

    pub event TokenRegistered(_ tokenId: String, _ maxSupply: UFix64, _ artist: Address)

    pub var AdminResourceStoragePath: StoragePath

    pub struct TokenStructure {
        pub var tokenId: String
        pub var symbol: String
        pub var issuedSupply: UFix64
        pub var maxSupply: UFix64
        pub var artist: Address
        pub var slope: UFix64
        pub var feeSplitterDetail : {Address:FeeStructure}
        pub var mintQoute: UFix64
        pub var reserve: UFix64
        pub var tokenResourceStoragePath: StoragePath
        pub var tokenResourcePublicPath: PublicPath
    
        init(_ tokenId: String, _ symbol: String, _ maxSupply: UFix64, _ artist: Address, tokenStoragePath:StoragePath, tokenPublicPath:PublicPath){
            self.tokenId = tokenId
            self.symbol = symbol
            self.issuedSupply = 0.0
            self.maxSupply = maxSupply
            self.artist = artist
            self.slope = 0.0005
            self.feeSplitterDetail = {}
            self.mintQoute = 0.0
            self.reserve = 0.0
            self.tokenResourceStoragePath = tokenStoragePath
            self.tokenResourcePublicPath = tokenPublicPath
        }

        access(account) fun incrementIssuedSupply(_ amount: UFix64){
            pre{
                self.issuedSupply + amount <= self.maxSupply : "max supply reached"
            }
            self.issuedSupply = self.issuedSupply + amount
        }
        access(account) fun setFeeSpliterDetail(_ feeSplitterDetail:{Address: FeeStructure}){
            pre {
            }
            self.feeSplitterDetail = feeSplitterDetail
        }
    }
    pub struct Artist {
        pub let address: Address
        pub let tokenIds: [String]

        init(_ address:Address){

            self.address = address
            self.tokenIds = []
        }
        access(account) fun addToken(_ tokenId: String){
            pre {
                self.tokenIds.contains(tokenId)==false:"Token already added"
            }
            self.tokenIds.append(tokenId)
        }
        

    }
    pub struct FeeStructure{
        pub var percentage: UFix64

        init(_ percentage: UFix64){
            self.percentage = percentage
        }

        access(account) fun updatePercentage(_ percentage: UFix64){ 
            pre {
                percentage >0.0: "Percentage should be greater than zero"
            }
            self.percentage = percentage
        }
    }



    pub resource Admin {

        pub fun registerToken( _ symbol: String, _ maxSupply: UFix64, _ feeSplitterDetail: {Address:FeeStructure}, _ artist: Address, tokenStoragePath:StoragePath, tokenPublicPath:PublicPath){
            pre{
                symbol !=nil: "symbol must not be null"
                maxSupply > 0.0: "max supply must be greater than zero"
            }
            let artistAddress = artist

            let tokenId = (symbol.concat("_")).concat(artistAddress.toString())            
            assert(Controller.allSocialTokens[tokenId]==nil, message: "token already registered")
            Controller.allSocialTokens[tokenId] = Controller.TokenStructure(tokenId, symbol, maxSupply, artistAddress, tokenStoragePath, tokenPublicPath)
            emit TokenRegistered(tokenId,maxSupply,artistAddress)
            Controller.allSocialTokens[tokenId]!.setFeeSpliterDetail(feeSplitterDetail)
        }
        init(){
        }
    }


    init(){
        self.allSocialTokens = {}
        self.allArtist = {}
        self.AdminResourceStoragePath = /storage/ControllerAdmin
        self.account.save<@Admin>(<- create Admin(), to : self.AdminResourceStoragePath)
    }
}