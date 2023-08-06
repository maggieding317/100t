import { timer, Subscription } from 'rxjs';
import { mergeMap } from 'rxjs/operators';
import { ethers } from "hardhat";
import { useContract } from "@thirdweb-dev/react/evm";


const { contract } = useContract("0x391f22144F8D459Ce653cfdD94D3140B34Ce054f") ;

let subscription: Subscription | undefined;

async function recordLiquidity() {
  // contract.call("recordTotalLiquidty");
  
  await contract.call("recordTotalLiquidty");
  // if (contract) {
    
  // }
}

function startRecording() {
  const reloadInterval = 86400;
  
  subscription = timer(0, reloadInterval).pipe(
    mergeMap(async () => recordLiquidity())
  ).subscribe();
}

function stopRecording() {
  if (subscription) {
    subscription.unsubscribe();
    subscription = undefined;
  }
}

// Start the recording
startRecording();

// Stop the recording after a certain duration
setTimeout(() => {
  stopRecording();
},  5 * 1000); // Stop after 24 hours (adjust the duration as needed)


// import { timer } from 'rxjs';
// import { mergeMap } from 'rxjs/operators';
// import { ethers } from "hardhat";
// import { useContract } from "@thirdweb-dev/react/evm";

// const { contract } = useContract("0x3a1B453435cC96b56bCeb56d0F6569846cd5b13E");

// async function recordLiquidity() {
//   if (contract) {
//     await contract.call("recordTotalLiquidty");
//   }
// }

// const reloadInterval = 86400;

// timer(0, reloadInterval).pipe(
//   mergeMap(async () => recordLiquidity())
// ).subscribe()




// async function d(){
//     const MTK = await ethers.getContractFactory("MyToken");
//     const mtk = await MTK.deploy();
//     await mtk.deployed();
// }

 // Your code here
//   mtk.call("recordTotalLiquidty");
    // mtk.recordTotalLiquidty();
    // await contract.call("recordTotalLiquidty");

// import { BigNumber } from "ethers";
// import { ethers } from "hardhat";

// describe("Greeter", function () {
//   it("Should set greetings", async function () {
//     const MTK = await ethers.getContractFactory("MyToken");
//     const mtk = await MTK.deploy();
//     await mtk.deployed();

//     const setGreetingsTx = await greeter.setGreetings([greetings]);
//     // wait until the transaction is mined
//     await setGreetingsTx.wait();
//   });
// });



// // Convert hours to milliseconds
// const hourInMillis = 60 * 60 * 1000;

// // Call myFunction every hour
// setInterval(myFunction, hourInMillis);

// function foo() {

//     // your function code here

//     setTimeout(foo, 5000);
// }

// foo();