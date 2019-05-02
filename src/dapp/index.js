import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {


        // contract.flightSuretyApp.events.FlightStatusInfo({
        //     fromBlock: 0
        // }, function (error, event) {
        //     if (error) console.log(error)
        //     console.log(event)
        // });

        /********************************************* Operational *******************************************/

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('dw-operational', 'Operational Status', 'Check if contract is operational', 
                        [ { label: 'Operational Status', error: error, value: result} ]);
        });

        /*************************************** Fund Airline Container **************************************/

        // Text Display
        display('dw-airline-fund', 'Fund Airline', 'Airline must submit 10 ether to participate', 
                [ { label: 'Must be FirstAir to submit funds.', error: null, value: contract.firstAirline} ]);

        // is Funded
        DOM.elid('btn-is-funded').addEventListener('click', () => {
            contract.isFundedAirline(contract.firstAirline,
                (error, result) => {
                    display('dw-airline-fund', '', '', [{ label: 'Is airline funded?', error: error, value: result}] );
            });
        });

        // Submit Funds
        DOM.elid('btn-airline-fund').addEventListener('click', () => {
            // Write transaction
            contract.fundAirline(contract.firstAirline,
                (error, result) => {
                    display('dw-airline-fund', '', '', [ { label: 'hash of tx:', error: error, value: result} ]);
            });

        });

        
        /*************************************** Buy Insurance Container **************************************/

        // Text Display
        display('dw-buy-insurance', 'Buy Insurance', 'Choose a Flight', 
                [ { label: '', error: null, value: ""} ]);

        contract.sampleFlights = {
            'A1': ["FirstAir", "LAX", "NYC", "2019-05-01:12:00:00"],
            'B2': ["FirstAir", "NYC", "SDQ", "2019-05-01:12:00:00"],
            'C3': ["FirstAir", "AMS", "DUB", "2019-05-01:12:00:00"],
        }

        // Display fake Flights in dropdown
        let flightList = DOM.elid("flightList");
        let x;
        for(x in contract.sampleFlights) {
            let li = document.createElement('li');
            li.innerHTML = `Flight ${x}:  Airline: ${contract.sampleFlights[x][0]}
               From: ${contract.sampleFlights[x][1]}     To: ${contract.sampleFlights[x][2]}    Date: ${contract.sampleFlights[x][3]}`
            flightList.appendChild(li);
        }

        // Chosen Flight
        DOM.elid("btn-buy-insurance-amount").addEventListener('click', () => {
        let chosen_flight = DOM.elid("flights-dropwdown").value;
            let amount = DOM.elid("insurance-amount").value;
            console.log(chosen_flight);
            if (amount <= 1) {
                console.log(amount);
                contract.buyInsurance(chosen_flight, amount, (error, result) => {
                    display('dw-buy-insurance', '', '', [ { label: 'hash of tx:', error: error, value: result} ]);
                });
            }
        });

        
        /*************************************** Fetch Flight Container **************************************/

        // User-submitted transaction
        DOM.elid('btn-submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('dw-submit-oracle', 'Oracles', 'Trigger oracles', 
                    [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        });


        /*************************************** Withdraw Funds Container **************************************/
        // Withdraw Funds
        DOM.elid('btn-withdraw-funds').addEventListener('click', () => {
            // let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.withdrawFunds( (error, result) => {
                display('dw-withdraw-funds', '', '', [ { label: 'hash of tx:', error: error, value: result} ]);
            });
        });
    

    });

    
})();




function display(wrapper, title, description, results) {
    let displayDiv = DOM.elid(wrapper);
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







