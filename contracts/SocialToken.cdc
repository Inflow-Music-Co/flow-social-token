import FungibleToken from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

pub contract SocialToken: FungibleToken {

    /// Total supply of ExampleTokens in existence
    pub var totalSupply: UFix64

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

        pub fun calculateMintQuote(amount: UFix64): UFix64 {
            return amount * SocialToken.mintQuote
        }

        /// mintTokens
        ///
        /// Function that mints new tokens, adds them to the total supply,
        /// and returns them to the calling context.
        ///
        pub fun mintTokens(amount: UFix64, fusdAmount: UFix64, fusdVault: @FUSD.Vault): @SocialToken.Vault? {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
            }
            
            SocialToken.totalSupply = SocialToken.totalSupply + amount

            SocialToken.mintQuote = self.calculateMintQuote(amount: amount)
            emit MintQuoteCalculated(quote: SocialToken.mintQuote)

            if(fusdAmount == SocialToken.mintQuote){
                // yay
                destroy fusdVault
                emit TokensMinted(amount: amount)
                return <-create Vault(balance: amount)
            } 
            
            destroy fusdVault
            panic("could not mint tokens, fusd not equal to mint quote")
        
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

        pub fun mintTokens(amount: UFix64, fusdAmount: UFix64, fusdVault: @FUSD.Vault): @SocialToken.Vault? {
            return <- self.minterCapability!
                .borrow()!
                .mintTokens(amount: amount, fusdAmount: fusdAmount, fusdVault: <- fusdVault)
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

        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @SocialToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
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

        pub fun burnTokens(from: @FungibleToken.Vault) {
            self.burnerCapability!.borrow()!.burnTokens(from: <- from)
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
        pub fun createNewMinter(): @Minter {
            emit MinterCreated()
            return <-create Minter()
        }

        /// createNewBurner
        ///
        /// Function that creates and returns a new burner resource
        ///
        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    init() {
        self.totalSupply = 1000.0
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



        let admin <- create Administrator()
        self.account.save(<-admin, to: /storage/socialTokenAdmin)

        // Emit an event that shows that the contract was initialized
        //
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}