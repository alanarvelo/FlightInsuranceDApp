import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        this.config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(this.config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            this.firstAirline = accts[1];

            let counter = 3;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            this.flightSuretyData.methods.authorizeCaller(this.config.appAddress)
                .send({from: this.owner}, (error, result) => {
                    // console.log(error, result)
                });

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.firstAirline,
            flight: flight,
            timestamp: 1555345902 //        Math.floor(Date.now() / 1000)
        } 

        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }


    isRegisteredAirline(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isRegisteredAirline(airline)
            .call({from: self.owner}, callback);
    }

    isFundedAirline(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isFundedAirline(airline)
            .call({from: self.owner}, callback);
    }


    fundAirline(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .fundAirline()
            .send({from: airline, value: this.web3.utils.toWei("1")}, callback);
    }

    buyInsurance(flight, amount, callback) {
        let self = this;
        console.log(this.passengers[0]);
        console.log(flight, this.web3.utils.toWei(amount.toString()) );
        self.flightSuretyApp.methods
            .buyInsurance(flight)
            .send( {from: this.passengers[0], value: this.web3.utils.toWei(amount.toString())}, (error, result) => {
                console.log(error, result);
                callback(error, result);
            })
    }


    withdrawFunds(callback) {
        let self = this;
        console.log(this.passengers[0]);
        self.flightSuretyData.methods
            .withdrawFunds()
            .send( {from: this.passengers[0]}, (error, result) => {
                console.log(error, result);
                callback(error, result);
            })
    }


    // (error, result) => {
    // callback(error, result)




    
}