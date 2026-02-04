// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract onChainToDoList {
    struct taskToAdd {
        uint taskId ;
        string task ;
        bool isCompleted ;
    }

    address public taskCreator ;
    constructor() {
        taskCreator = msg.sender ; // setting owner as me...
    }    

    uint public totalTasks ;
    mapping (address => taskToAdd) public taskList ; // array of task...
    function createNewTask(string memory text) public {
        taskToAdd memory newTask = taskToAdd( totalTasks , text , false ) ; // creating new task...
        taskList[msg.sender] = newTask ; // setting new task...
        totalTasks ++ ;
    }

    function updateTaskCompletion(address _storedBy ,bool updateValue) public {
        require(msg.sender == taskCreator , "UNAUTHORIZED for updation ABORTING!!");
        taskList[_storedBy].isCompleted = updateValue ; // getting the task...
    }
}

// Build a contract where:

// Users can add tasks (string)

// Each task has:

// taskId
// task
// isCompleted (true/false)

// Only task creator can mark it complete

// Anyone can read tasks