import path from "path"
import { init, emulator, getAccountAddress, deployContractByName, getContractCode, getContractAddress, getTransactionCode, getScriptCode, executeScript, sendTransaction } from "flow-js-testing";

jest.setTimeout(100000);

beforeAll(async () => {
  const basePath = path.resolve(__dirname, "../../Cadence");
  const port = 8080;

  await init(basePath, { port });
  await emulator.start(port);
});

afterAll(async () => {
  const port = 8080;
  await emulator.stop(port);
});


describe("Replicate Playground Accounts", () => {
  test("Create Accounts", async () => {
    // Playground project support 4 accounts, but nothing stops you jukeboxTemplateDatafrom creating more by following the example laid out below
    const Alice = await getAccountAddress("Alice");
    const Bob = await getAccountAddress("Bob");
    const Charlie = await getAccountAddress("Charlie");
    const Dave = await getAccountAddress("Dave");
    const Eve = await getAccountAddress("Eve");
    const Faythe = await getAccountAddress("Faythe");
    const Grace = await getAccountAddress("Grace");
    const Heidi = await getAccountAddress("Heidi");
    const Ivan = await getAccountAddress("Ivan");
    const Judy = await getAccountAddress("Judy");

    console.log(
      "Ten Playground accounts were created with following addresses"
    );
    console.log("Alice:", Alice);
    console.log("Bob:", Bob);
    console.log("Charlie:", Charlie);
    console.log("Dave:", Dave);
    console.log("Eve:", Eve);
    console.log("Faythe:", Faythe);
    console.log("Grace:", Grace);
    console.log("Heidi:", Heidi);
    console.log("Ivan:", Ivan);
    console.log("Judy:", Judy);
  });
});
describe("Deployment", () => {
  test("Deploy for FUSD", async () => {
    const name = "FUSD"
    const to = await getAccountAddress("Bob")
    let update = true

    const FungibleToken = "0xee82856bf20e2aa6"
    const addressMap = {
      FungibleToken
    };
    let result;
    try {
      result = await deployContractByName({
        name,
        to,
        addressMap,
        update,
      });
    } catch (e) {
      console.log(e);
    }
    expect(name).toBe("FUSD");

  });
  test("Deploy for Controller", async () => {
    const name = "Controller";
    const to = await getAccountAddress("Charlie");
    let update = true;
    const FungibleToken = "0xee82856bf20e2aa6"
    const FUSD = await getContractAddress("FUSD");

    let addressMap = {
      FungibleToken,
      FUSD
    };
    let result;
    try {
      result = await deployContractByName({
        name,
        to,
        addressMap,
        update,
      });
    }
    catch (e) {
      console.log(e)
    }

    expect(name).toBe("Controller");
  });
  test("Deploy for SocialToken", async () => {
    const name = "SocialToken";
    const to = await getAccountAddress("Dave");
    let update = true;
    const FungibleToken = "0xee82856bf20e2aa6"
    const FUSD = await getContractAddress("FUSD");
    const Controller = await getContractAddress("Controller")

    let addressMap = {
      FungibleToken,
      FUSD,
      Controller
    };
    let result;
    try {
      result = await deployContractByName({
        name,
        to,
        addressMap,
        update,
      });
    }
    catch (e) {
      console.log(e)
    }

    expect(name).toBe("SocialToken");
  });
});

describe("Transactions", () => {
  test("test transaction setup fusd vault", async () => {
    const name = "setupFusdVault";

    const accountNames = ["Charlie", "Eve", "Faythe", "Grace", "Heidi"]
    for (var i = 0; i < accountNames.length; i++) {
      // Import participating accounts
      const signer = await getAccountAddress(accountNames[i]);
      // Set transaction signers
      const signers = [signer];
      // Generate addressMap from import statements
      const FungibleToken = "0xee82856bf20e2aa6"
      const FUSD = await getContractAddress("FUSD");
      const addressMap = {
        FungibleToken,
        FUSD,
      };
      let code = await getTransactionCode({
        name,
        addressMap,
      });
      let txResult;
      try {
        txResult = await sendTransaction({
          code,
          signers,
        });
      } catch (e) {
        console.log(e);
      }
      console.log("tx Result", txResult);
    }
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction FUSD minter proxy", async () => {
    const name = "setup_fusd_minter";

    // Import participating accounts
    const Bob = await getAccountAddress("Bob");
    // Set transaction signers
    const signers = [Bob];

    // Generate addressMap from import statements
    const FUSD = await getContractAddress("FUSD");

    const addressMap = {
      FUSD,
    };

    let code = await getTransactionCode({
      name,
      addressMap,
    });

    let txResult;
    try {
      txResult = await sendTransaction({
        code,
        signers,
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction set minter FUSD", async () => {
    const name = "setMinterProxy";

    // Import participating accounts
    const Bob = await getAccountAddress("Bob");
    // Set transaction signers
    const signers = [Bob];

    // Generate addressMap from import statements
    const FUSD = await getContractAddress("FUSD");

    const addressMap = {
      FUSD,
    };
    let code = await getTransactionCode({
      name,
      addressMap,
    });
    const args = [Bob];

    // console.log(code);
    let txResult;
    try {
      txResult = await sendTransaction({
        code,
        signers,
        args
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction mint FUSD", async () => {
    const name = "mint_fusd";

    // Import participating accounts
    const Bob = await getAccountAddress("Bob");
    const Heidi = await getAccountAddress("Heidi")
    const Grace = await getAccountAddress("Grace")
    // Set transaction signers
    const signers = [Bob];

    // Generate addressMap from import statements
    const FungibleToken = "0xee82856bf20e2aa6"
    const FUSD = await getContractAddress("FUSD");

    const addressMap = {
      FUSD,
      FungibleToken,
    };
    let code = await getTransactionCode({
      name,
      addressMap,
    });
    const names = [Grace, Heidi]
    for (var i = 0; i < names.length; i++) {
      const args = [500.0, names[i]];

      // console.log(code);
      let txResult;
      try {
        txResult = await sendTransaction({
          code,
          signers,
          args
        });
      } catch (e) {
        console.log(e);
      }
      console.log("tx Result", txResult);
    }
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction register token", async () => {
    const name = "registerToken";

    // Import participating accounts
    const Charlie = await getAccountAddress("Charlie");

    const Eve = await getAccountAddress("Eve")
    const Faythe = await getAccountAddress("Faythe")

    // Set transaction signers
    const signers = [Charlie];

    // Generate addressMap from import statements
    const FungibleToken = "0xee82856bf20e2aa6"
    // const FUSD = await getContractAddress("FUSD");

    const addressMap = {
      // FUSD,
      FungibleToken
    };
    let code = await getTransactionCode({
      name,
      addressMap,
    });

    const names = [Eve, Faythe]
    const symbol = ["S", "N"]
    for (var i = 0; i < names.length; i++) {
      const args = [symbol[i], 10000.0, names[i]];
      // console.log(code);
      let txResult;
      try {
        txResult = await sendTransaction({
          code,
          signers,
          args
        });
      } catch (e) {
        console.log(e);
      }
      console.log("tx Result", txResult);
    }
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction setup social vault for account seven", async () => {
    const name = "setup_social_vault_5"

    const Grace = await getAccountAddress("Grace")

    const signers = [Grace]

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
  });
  test("test transaction setup social vault for account eight", async () => {
    const name = "setup_social_vault_6"

    const Heidi = await getAccountAddress("Heidi")

    const signers = [Heidi]

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
  })
  test("test transaction mint social token for account seven symbol S", async () => {
    const name = "mint_social_token_S";

    // Import participating accounts
    const Grace = await getAccountAddress("Grace");


    // Set transaction signers
    const signers = [Grace];

    // Generate addressMap from import statements
    const FungibleToken = "0xee82856bf20e2aa6"
    const FUSD = await getContractAddress("FUSD");
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FUSD,
      FungibleToken,
      SocialToken,
    };
    let code = await getTransactionCode({
      name,
      addressMap,
    });


    const args = [100.0, 100.0];
    // console.log(code);
    let txResult;
    try {
      txResult = await sendTransaction({
        code,
        signers,
        args
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction mint social token for account eight symbol N", async () => {
    const name = "mint_social_token_N";

    // Import participating accounts
    const Heidi = await getAccountAddress("Heidi");


    // Set transaction signers
    const signers = [Heidi];

    // Generate addressMap from import statements
    const FungibleToken = "0xee82856bf20e2aa6"
    const FUSD = await getContractAddress("FUSD");
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FUSD,
      FungibleToken,
      SocialToken,
    };
    let code = await getTransactionCode({
      name,
      addressMap,
    });


    const args = [100.0, 100.0];
    // console.log(code);
    let txResult;
    try {
      txResult = await sendTransaction({
        code,
        signers,
        args
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
    // expect(txResult[0].errorMessage).toBe("");
  });
  test("test transaction setup social vault for account seven ", async () => {
    const name = "setup_social_vault_6"

    const Grace = await getAccountAddress("Grace")

    const signers = [Grace]

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
  });
  test("test transaction setup social vault for account eight", async () => {
    const name = "setup_social_vault_5"

    const Heidi = await getAccountAddress("Heidi")

    const signers = [Heidi]

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
      });
    } catch (e) {
      console.log(e);
    }
    console.log("tx Result", txResult);
  })
  test("test transfer 50 S symbol token to account eight by account seven", async () => {
    const name = "transfer_token_7"

    const Grace = await getAccountAddress("Grace")

    const signers = [Grace]

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    const Heidi = await getAccountAddress("Heidi")

    let args = [50.0, Heidi]

    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
        args,
      })
    } catch (e) {
      console.log(e);
    }
    console.log(txResult);
  })
  test("test transfer 50 N symbol token to account seven by account eight", async () => {
    const name = "transfer_token_8"
    const Heidi = await getAccountAddress("Heidi")
    const signers = [Heidi]
    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")
    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    let code = await getTransactionCode({
      name,
      addressMap,
    })
    const Grace = await getAccountAddress("Grace")

    let args = [50.0, Grace]

    let txResult
    try {
      txResult = await sendTransaction({
        code,
        signers,
        args,
      })
    } catch (e) {
      console.log(e);

    }
    console.log(txResult);
  })
})
describe("Scripts", () => {

  test("test script for getting the fusd vault balance of multiple accounts", async () => {
    const name = "get_fusd_balance"


    const FUSD = await getContractAddress("FUSD")
    const FungibleToken = "0xee82856bf20e2aa6"

    const addressMap = {
      FUSD,
      FungibleToken
    }
    let code = await getScriptCode({
      name,
      addressMap,
    })
    code = code.toString().replace(/(?:getAccount\(\s*)(0x.*)(?:\s*\))/g, (_, match) => {
      const accounts = {
        "0x03": Charlie,
        "0x04": Dave,
      };
      const name = accounts[match];
      return `getAccount(${name})`;
    });
    const accountNames = ["Charlie", "Dave", "Eve", "Faythe", "Grace", "Heidi"]

    for (var i = 0; i < accountNames.length; i++) {
      const signerAddress = await getAccountAddress(accountNames[i])

      const args = [signerAddress]

      const result = await executeScript({
        code,
        args,
      })

      console.log(result);
    }

  })
  test("test script for getting the social vault balance of user 7", async () => {
    const name = "get_social_balance_7"

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    const Grace = await getAccountAddress("Grace")
    const args = [Grace]

    let code = await getScriptCode({
      name,
      addressMap,
    })
    code = code.toString().replace(/(?:getAccount\(\s*)(0x.*)(?:\s*\))/g, (_, match) => {
      const accounts = {
        "0x03": Charlie,
        "0x04": Dave,
      };
      const name = accounts[match];
      return `getAccount(${name})`;
    });
    const result = await executeScript({
      code,
      args
    })
    console.log(result);

  })
  test("test script for getting the social vault balance of user 8", async () => {
    const name = "get_social_balance_8"

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken,
    }
    const Heidi = await getAccountAddress("Heidi")
    const args = [Heidi]

    let code = await getScriptCode({
      name,
      addressMap,
    })
    code = code.toString().replace(/(?:getAccount\(\s*)(0x.*)(?:\s*\))/g, (_, match) => {
      const accounts = {
        "0x03": Charlie,
        "0x04": Dave,
      };
      const name = accounts[match];
      return `getAccount(${name})`;
    });
    const result = await executeScript({
      code,
      args
    })
    console.log(result);

  })
  test("test script get social balance for multiple tokens ", async () => {
    const name = "get_social_balance_multiple_tokens"

    const FungibleToken = "0xee82856bf20e2aa6"
    const SocialToken = await getContractAddress("SocialToken")

    const addressMap = {
      FungibleToken,
      SocialToken
    }
    let code = await getScriptCode({
      name,
      addressMap
    })

    code = code.toString().replace(/(?:getAccount\(\s*)(0x.*)(?:\s*\))/g, (_, match) => {
      const accounts = {
        "0x07": Grace,
        "0x08": Heidi,
      };
      const name = accounts[match];
      return `getAccount(${name})`;
    });
    const accountNames = ["Grace", "Heidi"]
    for (var i = 0; i < accountNames.length; i++) {

      var names = await getAccountAddress(accountNames[i])
      const args = [names]
      const result = await executeScript({
        code,
        args
      })
      console.log(result);
    }

  })
})
