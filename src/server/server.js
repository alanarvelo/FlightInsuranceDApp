import FlightSuretyAppMD from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
require("babel-polyfill");


let indexes = {};
let accounts = [];
const firstOracleAccount = 20;
const lastOracleAccount = 30;

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));



(async () => {

  await web3.eth.getAccounts().then( (res, err) =>{
    if (err) console.log(err);
    accounts = res;
    // console.log(accounts)
  });

  let flightSuretyApp = new web3.eth.Contract(FlightSuretyAppMD.abi, config.appAddress);

  await initializeOracles(flightSuretyApp);
  watchEvents(flightSuretyApp);
})();


async function initializeOracles(flightSuretyApp) {
  for(let a=firstOracleAccount; a<lastOracleAccount; a++) {
    try {
      // console.log(accounts[a])
      await flightSuretyApp.methods.registerOracle().send({from: accounts[a], value: web3.utils.toWei("1"), gas: 3009234}, (err, txHash) => {
        console.log(txHash);
      });
      indexes[a] = await flightSuretyApp.methods.getMyIndexes().call( {from: accounts[a]} );
      console.log(`Oracle ${a} Registered: ${indexes[a][0]}, ${indexes[a][1]}, ${indexes[a][2]}`);
         
    }
    catch(e){
      console.log(e)
    }
  }
}
 

async function watchEvents(flightSuretyApp) {
  flightSuretyApp.events.FlightStatusInfo({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});


  flightSuretyApp.events.OracleRequest( {fromBlock: 0}, async function (err, event) {
    // if (error) console.log(error);
    try {
      let eventInfo = event.returnValues;
      let index = parseInt(eventInfo['index']);
      let airline = eventInfo['airline'];   // should be type address, not string
      let flight = eventInfo['flight'];
      let timestamp = parseInt(eventInfo['timestamp'])
      console.log(index, airline, flight, timestamp);

      for (let b=firstOracleAccount; b<lastOracleAccount; b++){
        if (indexes[b].includes(index.toString())) {
          let statusCode = Math.floor(Math.random()*6)*10;
          await flightSuretyApp.methods.submitOracleResponse(index, airline, flight, timestamp, statusCode)
          .send({from: accounts[b]}, (err, txHash) => {
            console.log(txHash, statusCode, b)
          });
        }
      }
    }
    catch(e){
      console.log(e);
    }
  })
};



const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;