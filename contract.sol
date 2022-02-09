// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract brokechain {
    
    // We use finney (WT)
    uint256 public money_value = 1e15;
    uint256 public message_cost = 50;
    
    /*####################*\
      #      Owner       #
    \*####################*/

    address private owner;
    
    event owner_set(address indexed old_owner, address indexed new_owner);
    
    modifier is_owner() {
        require(msg.sender == owner, "Only owner can do that");
        _;
    }
    constructor() {
        owner = msg.sender;
        emit owner_set(address(0), owner);
    }
    function change_owner(address new_owner) public is_owner {
        emit owner_set(owner, new_owner);
        owner = new_owner;
    }
    function get_owner() external view returns (address) {
        return owner;
    }



    /*####################*\
      #     Manager      #
    \*####################*/

    address private manager = address(0);
    
    event manager_set(address indexed old_manager, address indexed new_manager);
    
    modifier is_manager() {
        require(msg.sender == manager, "Only manager can do that");
        _;
    }
    function change_manager(address new_manager) public is_owner {
        emit manager_set(manager, new_manager);
        manager = new_manager;
    }
    function get_manager() external view returns (address) {
        return manager;
    }



    /*####################*\
      #     Workers      #
    \*####################*/

    address[] private workers;

    function is_in_workers_list(address address_to_test) public view returns (bool){
        bool is_in_list = false;
        for (uint i=0; i < workers.length; i++) {
            if (workers[i] == address_to_test) {
                is_in_list = true;
                break;
            }
        }
        return is_in_list;
    }
    function add_worker(address new_worker) public is_manager {
        require(!is_in_workers_list(new_worker));
        require(new_worker != owner);
        require(new_worker != manager);
        workers.push(new_worker);
    }
    modifier is_worker() {
        require(is_in_workers_list(msg.sender), "Only worker can do that");
        _;
    }
    function remove_worker(address worker_to_remove) public is_manager {
        for (uint i=0; i < workers.length; i++) {
            if (workers[i] == worker_to_remove) {
                delete workers[i];
                break;
            }
        } 
    }
    function get_workers() public view returns (address[] memory){
        return workers;
    }



    /*####################*\
      #    Objectives    #
    \*####################*/

    struct objective {
        uint256 id;
        string title;
        uint256 value;
        address owner;
        bool complete;
        string[] messages;
    }

    //mapping(address => objective) private objectives;

    objective[] private objectives;

    function add_manager_objective(string memory title, uint value) public is_owner {
        require(manager != address(0));
        string[] memory messages_array;
        objectives.push(objective(objectives.length, title, value, manager, false, messages_array));
    }

    function add_objective(string memory title, uint value) public is_manager {
        string[] memory messages_array;
        objectives.push(objective(objectives.length, title, value, address(0), false, messages_array));
    }
    function get_objectives() public view returns (objective[] memory){
        return objectives;
    }

    function assign_objective(uint256 objective_id, address objective_owner) public is_manager {
        require(objectives[objective_id].owner != manager);
        require(is_in_workers_list(objective_owner));
        objectives[objective_id].owner = objective_owner;
    }
    function self_assign_objective(uint256 objective_id) public is_worker {
        require(objectives[objective_id].owner == address(0));
        objectives[objective_id].owner = msg.sender;
    }

    function check_objective(uint256 objective_id) public is_manager {
        require(objectives[objective_id].complete == false);
        objectives[objective_id].complete = true;
        if (objectives[objective_id].owner != address(0)) {
            balance -= objectives[objective_id].value;
            payable(objectives[objective_id].owner).transfer(objectives[objective_id].value * money_value);
        }
    }
    function check_manager_objective(uint256 objective_id) public is_owner {
        require(objectives[objective_id].owner == manager);
        require(objectives[objective_id].complete == false);
        objectives[objective_id].complete = true;
        if (objectives[objective_id].owner != address(0)) {
            balance -= objectives[objective_id].value;
            payable(objectives[objective_id].owner).transfer(objectives[objective_id].value * money_value);
        }
    }



    /*####################*\
      #     Messages     #
    \*####################*/

    function send_message(uint256 objective_id, string memory message) public {
        require((msg.sender == owner)||(msg.sender == manager)||(is_in_workers_list(msg.sender)));
        require(objectives[objective_id].complete == false);
        objectives[objective_id].messages.push(message);
        if(msg.sender == objectives[objective_id].owner){
            objectives[objective_id].value -= message_cost;
        }
    }


    
    /*#######################*\
      # Balance & contract  #
    \*#######################*/
    
    uint256 private balance = 0;
    
    receive() external payable {
        require((msg.value / money_value) > 0);
        balance += (msg.value / money_value);
    }
    function get_balance() public view returns (uint256){
        return balance;
    }
    
    function destroy_contract() public is_owner {
        selfdestruct(payable(owner));
    }
    
}