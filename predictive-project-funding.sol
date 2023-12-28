// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PredictiveProjectFunding {
    AggregatorV3Interface internal marketDataFeed;

    struct Project {
        string name;
        uint fundingGoal;
        uint currentFunding;
        bool funded;
    }

    Project[] public projects;
    address public owner;

    constructor(address _marketDataFeedAddress) {
        marketDataFeed = AggregatorV3Interface(_marketDataFeedAddress);
        owner = msg.sender;
    }

    function addProject(string memory _name, uint _fundingGoal) public {
        require(msg.sender == owner, "Only owner can add projects");
        projects.push(Project({
            name: _name,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            funded: false
        }));
    }

    function fundProject(uint _projectId) public payable {
        require(_projectId < projects.length, "Project does not exist");
        Project storage project = projects[_projectId];
        require(!project.funded, "Project already funded");
        
        project.currentFunding += msg.value;
        if (project.currentFunding >= project.fundingGoal) {
            project.funded = true;
        }
    }

    function shouldFundProject(uint _projectId) public view returns (bool) {
        require(_projectId < projects.length, "Project does not exist");
        (,int marketTrend,,,) = marketDataFeed.latestRoundData();
        return marketTrend > 0;
    }
}
