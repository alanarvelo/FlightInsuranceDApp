pragma solidity ^0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";


/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    address private firstAir;

    FlightSuretyData flightSuretyData;

    mapping(address => address[]) private proposedAirlinesVoters;

    



    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);

        // Create mock flights
        firstAir = address(0xf17f52151EbEF6C7334FAD080c5704D77216b732);
        bytes32 flightA1Key = getFlightKey(firstAir, "A1", 1555345902);
        bytes32 flightB2Key = getFlightKey(firstAir, "B2", 1555345902);
        bytes32 flightC3Key = getFlightKey(firstAir, "C3", 1555345902);
        flights[flightA1Key] = Flight(true, STATUS_CODE_UNKNOWN, 0, firstAir);
        flights[flightB2Key] = Flight(true, STATUS_CODE_UNKNOWN, 0, firstAir);
        flights[flightC3Key] = Flight(true, STATUS_CODE_UNKNOWN, 0, firstAir);
        
    }


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    //

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
        require(flightSuretyData.isOperational(), "Contract is currently not operational");     // Modify to call data contract's status
        _; 
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that assures new airlines are added by registered airlines and multi-consensus after 4th
    */
    modifier requireValidProposal(address _airline){
        require(_airline != address(0), "Proposed airline must be a valid address.");
        require(!isRegisteredAirline(_airline), "'airline' is already registered");

        bool duplicateVote = false;
        for (uint c=0; c < proposedAirlinesVoters[_airline].length; c++) {
            if (proposedAirlinesVoters[_airline][c] == msg.sender) {
                duplicateVote = true;
                break;
            }
        }
        require(!duplicateVote, "Caller has already voted for that airline");
        _;
    }


      /**
    * @dev Modifier that requires a registered airline to be the caller
    */
    modifier requireRegisteredAirline() {
        require(isRegisteredAirline(msg.sender), "Caller is not a registered airline");
        _;
    }

     /**
    * @dev Modifier that requires a funded airline to be the caller
    */
    modifier requireFundedAirline() {
        require(isFundedAirline(msg.sender), "Caller is not a funded airline");
        _;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) {
        return flightSuretyData.isOperational();    // Modify to call data contract's status
    }


    function isRegisteredAirline(address _airline) public view returns (bool){
        return flightSuretyData.isRegisteredAirline(_airline);
    }

    function isFundedAirline(address _airline) public view returns (bool){
        return flightSuretyData.isFundedAirline(_airline);
    }

    function getRegisteredAirlinesCount() internal view returns (uint8){
        return flightSuretyData.getRegisteredAirlinesCount();
    }

    function getFundedAirlinesCount() internal view returns (uint8){
        return flightSuretyData.getFundedAirlinesCount();
    }

    function isInsured(string _flight) public view returns (uint256){
        bytes32 _flightKey = getFlightKey(firstAir, _flight, 1555345902);
        return flightSuretyData.isInsured(_flightKey, msg.sender);
    }

    function isCredited() public view returns (uint256){
        return flightSuretyData.isCredited(msg.sender);
    }
    




    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /*************************************** Airline Logic **************************************/

  
   /**
    * @dev Add an airline to the registration queue
    */   
    function registerAirline(address _airline, string _name) external requireFundedAirline requireValidProposal(_airline) returns(bool success, uint256 votes) {
        uint8 registeredAirlinesCount = getRegisteredAirlinesCount();
        if (registeredAirlinesCount <= 3) {
            flightSuretyData.registerAirline(_airline, _name);
        } else {
            proposedAirlinesVoters[_airline].push(msg.sender);
            if (proposedAirlinesVoters[_airline].length >= registeredAirlinesCount/2) {
                proposedAirlinesVoters[_airline] = new address[](0);
                flightSuretyData.registerAirline(_airline, _name);
            }
        }
        return (isRegisteredAirline(_airline), proposedAirlinesVoters[_airline].length);
    }

    /**
    * @dev Process & Submit an airlines funding
    */  
    function fundAirline() public requireRegisteredAirline payable {
        require(!isFundedAirline(msg.sender), "Airline already Funded");
        require(msg.value >= 1 ether, "Must submit 10 ether to start operating as an airline");
        flightSuretyData.fundAirline.value(msg.value)(msg.sender);          // unsure if this will work, check on posts & questions
    }

    // /**
    // * @dev Process & Submit an airlines funding
    // */  
    // function getAirlineInfo(address _airline) public returns(string name, bool isRegistered, bool isFunded) {
    //     return flightSuretyData.getAirlineInfo(_airline); 
    // }




    /*************************************** Passenger Logic **************************************/

    /**
    * @dev Buy insurance for a flight
    */   
    function buyInsurance(string _flight) public requireIsOperational payable {
        // require(msg.value <= 1 ether, "Payment invalid. Max payment is 1 ether");
        bytes32 _flightKey = getFlightKey(firstAir, _flight, 1555345902);
        // require(flights[_flightKey].isRegistered = true, "Flight is not registered, or invalid, to purchase insurance");
        
        flightSuretyData.buyInsurance.value(msg.value)(_flightKey, msg.sender); 
    }

    

    // Call creditInsurees from here when need be
    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(string _flight) public requireIsOperational requireContractOwner {
        bytes32 _flightKey = getFlightKey(firstAir, _flight, 1555345902);
        flightSuretyData.creditInsurees(_flightKey);

    }

    // // Call creditInsurees from here when need be
    // /**
    //  *  @dev Credits payouts to insurees
    // */
    // function withdrawFunds() public requireIsOperational {
    //     flightSuretyData.withdrawFunds(msg.sender);
    // }












//    /**
//     * @dev Register a future flight for insuring.
//     *
//     */  
//     function registerFlight() external pure {
  
//     }

    /*************************************** Oracle Logic **************************************/
    
   /**
    * @dev Called after oracle has updated flight status
    */  
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal {
        uint256 time = timestamp + statusCode;
        address new_airline = airline;
        string memory new_flight = flight;
        if (statusCode == 40) {
            creditInsurees(flight);
        }
   
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external {
        require(isRegisteredAirline(airline), "This airline is not registered, can't process flights of unregistered airlines");
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        require(flights[flightKey].isRegistered, "This flight is not registered, can't process unregistered flights.");

        uint8 index = getRandomIndex(msg.sender);
        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   
