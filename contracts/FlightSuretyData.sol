pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedContracts;               // List of App Contracts that can call in

    struct Airline {                                                    // Airline Struct object
        string name;
        bool isRegistered;
        bool isFunded;
    }

    mapping(address => Airline) public airlines;                        // To track registered and funded airlines
    uint8 private registeredAirlinesCount;                              
    uint8 private fundedAirlinesCount;     

    mapping(bytes32 => address[]) private insuredPassengers;
    mapping(bytes32 => mapping(address => uint256)) private passengersInsurance;
    
    mapping(address => uint256) private passengersCredit;

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(string _firstAirlineName, address _firstAirline) public {
        contractOwner = msg.sender;
        airlines[_firstAirline].name = _firstAirlineName;
        airlines[_firstAirline].isRegistered = true;
        registeredAirlinesCount = 1;
        authorizedContracts[contractOwner] = true;

    }


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; 
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner(){
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    // /**
    // * @dev Modifier that requires the Contract/Caller to be authorized
    // */
    modifier requireAuthorizedCaller() {
        require(authorizedContracts[msg.sender], "Caller/Contract is not authorized");
        _;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    * can leverage fifth+ airline addition multisig for this fn too
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        require(mode != operational, "new mode is equal to current operational status");
        operational = mode;
    }

    /**
    * @dev Give access to a contract/caller to call fns in this contract
    */   
    function authorizeCaller(address contractAddress) external requireContractOwner requireIsOperational {
        authorizedContracts[contractAddress] = true;
    }


    /**
    * @dev Remove access for a contract/caller to call fns in this contract
    */   
    function deauthorizeCaller(address contractAddress) external requireContractOwner requireIsOperational {
        delete authorizedContracts[contractAddress];
    }

    /**
    * @dev Indicate if an airline is registered
    */   
    function isRegisteredAirline(address _airline) public view returns (bool) {
        return airlines[_airline].isRegistered;
    }

    /**
    * @dev Indicate if an airline is registered
    */   
    function isFundedAirline(address _airline) public view returns (bool) {
        return airlines[_airline].isFunded;
    }

    /**
    * @dev Indicate Number of registered airlines
    */   
    function getRegisteredAirlinesCount() public view returns (uint8) {
        return registeredAirlinesCount;
    }

    /**
    * @dev Indicate Number of funded airlines
    */   
    function getFundedAirlinesCount() public view returns (uint8) {
        return fundedAirlinesCount;
    }

    /**
    * @dev Indicate wether a Passenger has purchased insurance for a flight
    */   
    function isInsured(bytes32 _flightKey, address _passenger) external view returns (uint256) {
        return passengersInsurance[_flightKey][_passenger];
    }

    /**
    * @dev Indicate wether a Passenger has been credited for a delayed flight
    */   
    function isCredited(address _passenger) external view returns (uint256) {
        return passengersCredit[_passenger];
    }


    // /**
    // * @dev Process & Submit an airlines funding
    // */  
    // function getAirlineInfo(address _airline) public returns(Airline) {
    //     return airlines[_airline];
    // }

// string name, bool isRegistered, bool isFunded
// .name, airlines[_airline].isRegistered , airlines[_airline].isFunded)

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /****************************************** Airline Logic ***********************************/

   /**
    * @dev Add an airline to the registration queue
    */   
    function registerAirline(address _airline, string _name) external requireIsOperational requireAuthorizedCaller {
        airlines[_airline].isRegistered = true;
        airlines[_airline].name = _name;
        registeredAirlinesCount += 1;      
    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    */   
    function fundAirline(address _airline) external requireIsOperational requireAuthorizedCaller payable {
        require(msg.value >= 1 ether);
        airlines[_airline].isFunded = true;
        fundedAirlinesCount += 1;
    }


    /***************************************** Passenger Logic **********************************/

   /**
    * @dev Buy insurance for a flight
    */   
    function buyInsurance(bytes32 _flightKey, address _passenger) external requireIsOperational requireAuthorizedCaller payable {
        // require(msg.value <= 1 ether, "Payment invalid. Max payment is 1 ether");

        insuredPassengers[_flightKey].push(_passenger);
        passengersInsurance[_flightKey][_passenger] = msg.value;
    }


    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 _flightKey) external requireIsOperational requireAuthorizedCaller {
        // iterate over mapping
        // create another bytes32 => address[] mapping
        for (uint i=0; i < insuredPassengers[_flightKey].length; i++) {
            address _passenger = insuredPassengers[_flightKey][i];
            passengersCredit[_passenger] = passengersInsurance[_flightKey][_passenger]*3/2;
        }

    }
    

        /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function withdrawFunds() public requireIsOperational {
        require(passengersCredit[msg.sender] > 0 ether, "Sender has no insurance credit to withdraw");
        uint256 funds = passengersCredit[msg.sender];
        passengersCredit[msg.sender] = 0;
        msg.sender.transfer(funds);

    }






    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }


    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() public payable {
        // fundAirline();
    }


}

