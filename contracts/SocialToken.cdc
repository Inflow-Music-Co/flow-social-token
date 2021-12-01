import FungibleToken from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

pub contract SocialToken: FungibleToken {

    /// Total supply of ExampleTokens in circulation
    pub var totalSupply: UFix64

    /// Total amount of tokens allowed to be minted
    pub var maximumSupply: UFix64

    /// Minimum required FUSD to mint new tokens
    pub var mintQuote: UFix64

    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// The event that is emitted when a mintQuote is calculate
    pub event MintQuoteCalculated(quote: UFix64)

    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// The event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// The event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

     /// The event that is emitted when a new minter resource is created
    pub event MinterCreated()

    /// The event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    // The storage path for the admin resource
    pub let AdminStoragePath: StoragePath

    // The storage Path for minters' MinterProxy
    pub let MinterProxyStoragePath: StoragePath

    // The public path for minters' MinterProxy capability
    pub let MinterProxyPublicPath: PublicPath

    // The storage Path for minters' MinterProxy
    pub let BurnerProxyStoragePath: StoragePath

    // The public path for minters' MinterProxy capability
    pub let BurnerProxyPublicPath: PublicPath

    pub var AdminPool: FUSDPool

   pub struct FUSDPool {
        // The receiver for the FUSD Collateral.
        // Note that we do not store an address to find the Vault that this represents,
        // as the link or resource that we fetch in this way may be manipulated,
        // so to find the address that a cut goes to you must get this struct and then
        // call receiver.borrow()!.owner.address on it.
        // This can be done efficiently in a script.
        pub let receiver: Capability<&{FungibleToken.Receiver}>

        // The provider for the FUSD Collateral, this is used to deposit FUSD
        // back to the signer's wallet after they burn
        pub let provider: Capability<&{FungibleToken.Provider}>

      

        // The amount of the payment FungibleToken that will be paid to the receiver. use later 
        // for splits
        // pub let amount: UFix64

        // initializer
        //
        init(
            receiver: Capability<&{FungibleToken.Receiver}>, 
            provider: Capability<&{FungibleToken.Provider}>
            ) {
            self.receiver = receiver
            self.provider = provider
        }
    }

    /// Vault
    ///
    /// Each user stores an instance of only the Vault in their storage
    /// The functions in the Vault and governed by the pre and post conditions
    /// in FungibleToken when they are called.
    /// The checks happen at runtime whenever a function is called.
    ///
    /// Resources can only be created in the context of the contract that they
    /// are defined in, so there is no way for a malicious user to create Vaults
    /// out of thin air. A special Minter resource needs to be defined to mint
    /// new tokens.
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        /// The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the money that is being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @SocialToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            SocialToken.totalSupply = SocialToken.totalSupply - self.balance
        }
    }

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub fun getMintQuote(amount: UFix64): UFix64 {
        return amount * SocialToken.mintQuote
    }

    /// Minter
    ///
    /// Resource object that token admin accounts can hold to mint new tokens.
    ///
    pub resource Minter {

        access(self) let pool: FUSDPool

        pub fun calculateMintQuote(amount: UFix64): UFix64 {
            return amount * SocialToken.mintQuote
        }

        /// mintTokens
        ///
        /// Function that mints new tokens, in exchange for fusdPayment. If Payment is equal to the quote 
        /// FUSD Vault gets sent to administrator account 
        /// and returns the minted SocialTokens to the calling context.
        ///
        pub fun mintTokens(amount: UFix64, fusdPayment: @FungibleToken.Vault): @FungibleToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
            }
            
            SocialToken.totalSupply = SocialToken.totalSupply + amount

            SocialToken.mintQuote = self.calculateMintQuote(amount: amount)
            emit MintQuoteCalculated(quote: SocialToken.mintQuote)

            //@TODO calculate creator splits and add to this code block
            if(fusdPayment.balance == SocialToken.mintQuote){
                let receiver = self.pool.receiver.borrow()!
                let payment <- fusdPayment.withdraw(amount: fusdPayment.balance)
                receiver!.deposit(from: <- payment)
                destroy fusdPayment
                emit TokensMinted(amount: amount)
                return <-create Vault(balance: amount)
            }
            
            log("could not mint tokens, fusd not equal to mint quote") 
            return <- fusdPayment
            
        }

        init(pool: FUSDPool) {
            self.pool = pool
        }
    }

    pub resource interface MinterProxyPublic {
        pub fun setMinterCapability(cap: Capability<&Minter>)
    }

    pub resource MinterProxy: MinterProxyPublic {

        //access(self) so nobody else can copy the capability and use it.
        access(self) var minterCapability: Capability<&Minter>?

        // Anyone can call this, but only the admin can create Minter capabilities,
        // so the type system constrains this to being called by the admin.
        pub fun setMinterCapability(cap: Capability<&Minter>) {
            self.minterCapability = cap
        }

        pub fun mintTokens(amount: UFix64, fusdPayment: @FungibleToken.Vault): @FungibleToken.Vault {
            return <- self.minterCapability!
                .borrow()!
                .mintTokens(amount: amount, fusdPayment: <- fusdPayment)
        }

        init() {
            self.minterCapability = nil
        }
    }

    // createMinterProxy
    //
    // Function that creates a MinterProxy.
    // Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
    // and only the admin can provide that.
    //

    pub fun createMinterProxy(): @MinterProxy {
        return <- create MinterProxy()
    }

    /// Burner
    ///
    /// Resource object that token admin accounts can hold to burn tokens.
    ///
    pub resource Burner {

        access(self) let pool: FUSDPool

        pub fun calculateBurnQuote(amount: UFix64): UFix64 {
            return amount * SocialToken.mintQuote
        }

        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        pub fun burnTokens(from: @FungibleToken.Vault): @FungibleToken.Vault {
            let vault <- from as! @SocialToken.Vault
            let provider = self.pool.provider.borrow()!
            let paymentAmount = self.calculateBurnQuote(amount: vault.balance)
            let payment <- provider!.withdraw(amount: paymentAmount)
            
            emit TokensBurned(amount: vault.balance)
            destroy vault
            return <- payment
        }

        init(pool: FUSDPool) {
            self.pool = pool
        }
    }

    pub resource interface BurnerProxyPublic {
        pub fun setBurnerCapability(cap: Capability<&Burner>)
    }

    pub resource BurnerProxy: BurnerProxyPublic {

        //access(self) so nobody else can copy the capability and use it.
        access(self) var burnerCapability: Capability<&Burner>?

        // Anyone can call this, but only the admin can create Burner capabilities,
        // so the type system constrains this to being called by the admin.
        pub fun setBurnerCapability(cap: Capability<&Burner>) {
            self.burnerCapability = cap
        }

        pub fun burnTokens(from: @FungibleToken.Vault): @FungibleToken.Vault {
            return <- self.burnerCapability!
                .borrow()!
                .burnTokens(from: <- from)
        }

        init() {
            self.burnerCapability = nil
        }
    }

    // createBurnerProxy
    //
    // Function that creates a BurnerProxy.
    // Anyone can call this, but the BurnerProxy cannot mint without a Burner capability,
    // and only the admin can provide that.
    //

    pub fun createBurnerProxy(): @BurnerProxy {
        return <- create BurnerProxy()
    }

    pub resource Administrator {

        /// createNewMinter
        ///
        /// Function that creates and returns a new minter resource
        ///
        pub fun createNewMinter(pool: SocialToken.FUSDPool): @Minter {
            emit MinterCreated()
            return <-create Minter(pool: pool)
        }

        /// createNewBurner
        ///
        /// Function that creates and returns a new burner resource
        ///
        pub fun createNewBurner(pool: SocialToken.FUSDPool): @Burner {
            emit BurnerCreated()
            return <-create Burner(pool: pool)
        }
    }

    init() {
        self.totalSupply = 1000.0
        self.maximumSupply = 10000000.0
        self.mintQuote = 2.0

        self.AdminStoragePath = /storage/socialTokenAdmin
        self.MinterProxyPublicPath = /public/socialTokenMinterProxy
        self.MinterProxyStoragePath = /storage/socialTokenMinterProxy
        
        self.BurnerProxyPublicPath = /public/socialTokenBurnerProxy
        self.BurnerProxyStoragePath = /storage/socialTokenBurnerProxy

        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: /storage/socialTokenVault)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        self.account.link<&{FungibleToken.Receiver}>(
            /public/socialTokenReceiver,
            target: /storage/socialTokenReceiver
        )

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        self.account.link<&SocialToken.Vault{FungibleToken.Balance}>(
            /public/socialTokenBalance,
            target: /storage/socialTokenVault
        )

        self.AdminPool = FUSDPool(
            receiver: self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver),
            provider: self.account.getCapability<&FUSD.Vault{FungibleToken.Provider}>(/public/fusdProvider)
            )

        let admin <- create Administrator()
        self.account.save(<-admin, to: /storage/socialTokenAdmin)

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}