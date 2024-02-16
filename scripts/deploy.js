const { ethers, run, network } = require("hardhat")



async function main () {
  //Main_variables
  const owner_wallet = "0x4029Dd1A8D674B7Fd2Ee0cc31AEc61294B117491"
  const multisig_wallet = "0x86b6002Aa23158Fa8c29db9a0b4bc5F0b2152C77"
  // const usdcontractmainnet= "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8" THIS SHOULD BE UNCOMMENTED USING MAIN NET

  //FARMCOIN AUTHORITY SETUP
  const FarmCoinAuthorityFactory = await ethers.getContractFactory("FarmCoinAuthority")
  console.log("Deploying Contract ...")
  const farmcoinauthority = await FarmCoinAuthorityFactory.deploy(
    owner_wallet,owner_wallet,owner_wallet,multisig_wallet
  )
  await farmcoinauthority.deployed()
  console.log(`Deployed contract to : ${farmcoinauthority.address}`)
  console.log("Waiting for block confirmations...")
  await farmcoinauthority.deployTransaction.wait(6)
  await verify(farmcoinauthority.address, [owner_wallet,owner_wallet,owner_wallet,multisig_wallet])

  //FARMCOIN SETUP
  const farmcoinauthorityaddress = farmcoinauthority.address 
  const FarmCoinFactory = await ethers.getContractFactory("FarmCoin")
  console.log("Deploying Contract ...")
  const farmcoin = await FarmCoinFactory.deploy(farmcoinauthorityaddress)
  await farmcoin.deployed()
  console.log(`Deployed contract to : ${farmcoin.address}`)
  //MINT TOTAL SUPPLY
  const mintFarmcoin = await farmcoin.mintOwner(BigInt(100000000000000000000000000))
  console.log("Waiting for block confirmations...")
  await farmcoin.deployTransaction.wait(6)
  await verify(farmcoin.address, [farmcoinauthorityaddress])

  //USDC SETUP THIS SHOULD BE COMMENTED USING MAIN NET
  const farmcoinaddress = farmcoin.address
  const USDCFactory = await ethers.getContractFactory("USDC")
  console.log("Deploying Contract ...")
  const usdc = await USDCFactory.deploy(farmcoinauthorityaddress)
  await usdc.deployed()
  console.log(`Deployed contract to : ${usdc.address}`)
  const mintUsdc = await usdc.mint(owner_wallet,BigInt(1000000000000))
  console.log("Waiting for block confirmations...")
  await usdc.deployTransaction.wait(6)
  await verify(usdc.address, [farmcoinauthorityaddress])

  //POOLS SETUP
  const usdcaddress = usdc.address //THIS SHOULD BE COMMENTED USING MAIN NET

  // const usdcaddress = usdcontractmainnet THIS SHOULD BE UNCOMMENTED USING MAIN NET
  const DepositContractFactory = await ethers.getContractFactory("DepositContract")
  console.log("Deploying Contract ...")
  const depositcontract = await DepositContractFactory.deploy(farmcoinaddress,usdcaddress,farmcoinauthorityaddress)
  await depositcontract.deployed()
  console.log(`Deployed contract to : ${depositcontract.address}`)
  console.log("Waiting for block confirmations...")
  await depositcontract.deployTransaction.wait(6)
  await verify(depositcontract.address, [farmcoinaddress,usdcaddress,farmcoinauthorityaddress])

//   //Presale SETUP
  const PresaleFactory = await ethers.getContractFactory("Presale")
  console.log("Deploying Contract ...")
  const presalecontract = await PresaleFactory.deploy(farmcoinaddress,farmcoinauthorityaddress)
  await presalecontract.deployed()
  console.log(`Deployed contract to : ${presalecontract.address}`)
  console.log("Waiting for block confirmations...")
  await presalecontract.deployTransaction.wait(6)
  await verify(presalecontract.address, [farmcoinaddress,farmcoinauthorityaddress])
 }

const verify = async (contractAddress, args) => {
  console.log("Verifying contract...")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!")
    } else {
      console.log(e)
    }
  }
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

