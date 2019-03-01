pragma solidity ^0.5.0;

// import libraries
import "./SafeMath.sol";

// import contracts
import "./EcogyOracle.sol";
import "./SafeMath.sol";

contract Ecogy is EcogyOracle {
    using SafeMath for uint256;
    
   /// TYPE DECLARATIONS
    struct Project {
        uint projectId;       // project identifier
        bool available;       // true if project still has capacity for investment
        uint price;           // how much it costs to invest in the project
        address[] investors;  // array of investor addresses for this project
        uint[] holdings;      // no of shares held by each investor
        uint availableShares; // number of shares available to purchase
    }
    
    struct Investor {
        bool hasInvested;    // true if already invested in a project
        uint[] investments;  // array of project id's that Investor has invested in
        uint[] holdings;     // no of shares held in each project
        uint shareBalance;   // number of shares that investor holds
    }
    
    // conditions to prevent undesirable function calls
    modifier condition(bool _condition, string memory _message) {
        require(_condition, _message);
        _;
    }

    modifier onlyEcogy() {
        require(msg.sender == ecogy, "Only Ecogy Energy can call this.");
        _;
    }
    
   /// STATE VARIABLES
    // declare payable ether account addresses for ecogy
    address payable public ecogy;    
    // Mapped Structs with Index [storage pattern]
    uint[] public projectList;
    mapping(uint => Project) public projectMap;    
    // state variable that stores an investor struct for each possible address
    mapping(address => Investor) public investorMap;
    Investor[] investorList;
    
    mapping (address => uint) public pendingWithdrawals;
    mapping (address => uint) public pendingROI;
    
    uint lastROICall = 0;
    
   /// EVENTS
    // declare events
    // these are to be used later by the JS app to display changes on the webpage
    event ProjectCreated(uint id);
    event InvestmentMade(uint id, uint numShares);
    event ProjectFull();
    
   /// CONSTRUCTOR FUNCTION
    // initialise the contract with two demo projects for testing purposes
    constructor() public payable {
        ecogy = msg.sender;
        // demo projects
        Project storage demo1 = projectMap[1];        
        demo1.projectId = 1;
        demo1.available = true;
        demo1.price = 2*10**16;
        demo1.availableShares = 100;
        projectList.push(demo1.projectId);

        Project storage demo2 = projectMap[2];
        demo2.projectId = 2;
        demo2.available = true;
        demo2.price = 1*10**16;
        demo2.availableShares = 100;
        projectList.push(demo2.projectId);
    }
    
   /// PUBLIC FUNCTIONS 
    // invest in a project
    function invest(uint _projectId, uint numShares) public payable {
        // ensure transaction value is correct
        require(msg.value == (projectMap[_projectId].price.mul(numShares)), 'attach the correct amount of ether');
        // ensure project id is valid
        require(projectMap[_projectId].available, 'project with that id is not available to invest in');
        // ensure number of shares is valid
        require(projectMap[_projectId].availableShares >= numShares && numShares>0, 'project does not have that many shares available');
        // check if investor exists
        if (!investorMap[msg.sender].hasInvested) { // investor does not exist
                // create new investor struct
            Investor storage newInvestor = investorMap[msg.sender];
            investorList.push(newInvestor);
            
            // update investor details and project details
            newInvestor.investments.push(_projectId);
            newInvestor.holdings.push(numShares);
            newInvestor.hasInvested = true;
            newInvestor.shareBalance = numShares;
            projectMap[_projectId].investors.push(msg.sender);
            projectMap[_projectId].holdings.push(numShares);
        } else { // investor exists
            // get investor struct
            Investor storage currInvestor = investorMap[msg.sender];
            
            // find selected project in investor struct using basic algorithm
            uint len = currInvestor.investments.length;
            bool found = false;
            uint i = 0;
            
            while(!found && i<len) {
                if (_projectId == currInvestor.investments[i]) {found = true;}
                i++;
            }
            
            if(found) { // investor has previously invested in selected project
                // update investor balances
                currInvestor.shareBalance = currInvestor.shareBalance.add(numShares);
                currInvestor.holdings[i-1] = currInvestor.holdings[i-1].add(numShares);
                
                // find investor in selected project struct
                len = projectMap[_projectId].investors.length;
                i = 0;
                found = false;
                
                while (!found && i<len) {
                    if (projectMap[_projectId].investors[i] == msg.sender) {found = true;}
                    i++;
                }
                // update project balances
                projectMap[_projectId].holdings[i-1] += numShares;    
            } else {
                // investor exists but has not yet invested in selected project
                // update investor and project balances
                currInvestor.investments.push(_projectId);
                currInvestor.holdings.push(numShares);
                currInvestor.shareBalance = currInvestor.shareBalance.add(numShares);
                projectMap[_projectId].investors.push(msg.sender);
                projectMap[_projectId].holdings.push(numShares);
            }
        }
        
        // update availableShares in project struct
        projectMap[_projectId].availableShares = projectMap[_projectId].availableShares.sub(numShares);
        
        pendingWithdrawals[msg.sender] += msg.value;
        
        emit InvestmentMade(_projectId, numShares);
    }

    // make a project available to invest in
    function createProject(uint _projectId, uint _price) onlyEcogy public {
        require(_price >= 0, "Cannot have a negative price");
        require(!projectMap[_projectId].available, 'project with that id already exists');
        
        // create new project struct
        Project storage newProject = projectMap[_projectId];
        address[] memory _investors; // initialise investors address array
        uint[] memory _holdings;
        
        newProject.projectId = _projectId;
        newProject.available = true;
        newProject.price = _price;
        newProject.investors = _investors;
        newProject.holdings = _holdings;
        newProject.availableShares = 100;
        
        // append project list
        projectList.push(newProject.projectId);
        
        emit ProjectCreated(_projectId);
    }
    
    function deleteProject(uint _id) onlyEcogy public payable {
        require(projectMap[_id].available, 'project with that id does not exist');
        for (uint i = 0; i < projectMap[_id].investors.length; i++) {
            address payable investor = address(uint160(projectMap[_id].investors[i]));
            divest(_id, investor);
        }
        projectMap[_id].available = false;
    }
    
    function sellShares(uint _projectId) public {
        address payable a = msg.sender;
        uint i = _projectId;
        divest(i, a);
        emit InvestmentMade(_projectId, 0);
    }

    // calculate amount of ether investor is owed
    
    function calculateReturn(uint _projectId) public returns (uint) {
        // logic to only have this called once per period???
        require(now - lastROICall > 4 weeks, 'RoI already calculated for this month');
        
        // HAVE TO PUT IN UPDATE() CALL BEFORE CALLING THIS FROM FRONTEND 
        // get investments of msg.sender
        uint i = getIndex(_projectId, investorMap[msg.sender].investments);
        // calculate value of investment in ether
        uint sharesHeld = investorMap[msg.sender].holdings[i];
        pendingROI[msg.sender] += earningpershare.mul(sharesHeld);
        if (earningpershare.mul(sharesHeld) > 0) lastROICall = now;
        return earningpershare.mul(sharesHeld);   
    }
    
    function sendROI(address payable _shareholder) public onlyEcogy payable {
        uint ROI;
        pendingROI[_shareholder] = ROI;
        pendingROI[_shareholder] = 0;
        _shareholder.transfer(ROI);
    }

    // Getters
    function getProjectList() public view returns (uint[] memory) {
        return projectList;
    }

    function getProject(uint id) 
        public 
        view 
        returns (uint, bool, uint, address[] memory, uint[] memory, uint) 
    {
        require(projectMap[id].available, 'project with that id does not exist');
        return (
            projectMap[id].projectId, 
            projectMap[id].available, 
            projectMap[id].price, 
            projectMap[id].investors, 
            projectMap[id].holdings, 
            projectMap[id].availableShares
            );
    }

    function getInvestor() 
        public 
        view 
        returns (bool, uint[] memory, uint[] memory, uint)
    {
        return (
            investorMap[msg.sender].hasInvested,
            investorMap[msg.sender].investments,
            investorMap[msg.sender].holdings,
            investorMap[msg.sender].shareBalance
            );
    }
   
    function contractBalance() public view returns (uint) { return address(this).balance; }
   
     
   /// INTERNAL FUNCTIONS
   // sell all shares in specific project
    function divest(uint _projectId, address payable _shareholder) internal {
        // retrieve project details
        uint index;
        address[] memory array = projectMap[_projectId].investors;
        index = getAddressIndex(_shareholder, array);
        
        uint shares = projectMap[_projectId].holdings[index];
        uint owed = shares * projectMap[_projectId].price;
        
        // revert if zero share balance
        require(shares >= 0, 'No shares owned in this project');
        // build this into the web app code^^
        
        // withdrawal pattern
        pendingWithdrawals[_shareholder] -= owed;
        _shareholder.transfer(owed);
        
        projectMap[_projectId].holdings[index] = 0;
        projectMap[_projectId].availableShares = projectMap[_projectId].availableShares.add(shares);
        
        uint[] memory investments = investorMap[_shareholder].investments;
        index = getIndex(_projectId, investments);
        
        investorMap[_shareholder].holdings[index] = 0;
        investorMap[_shareholder].shareBalance = investorMap[_shareholder].shareBalance.sub(shares);
    }

    function getAddressIndex(address _address, address[] memory _array) 
        internal 
        pure 
        returns (uint) 
    {
        require(_array.length > 0, 'could not find investor address');
        for (uint i = 0; i < _array.length; i++) {
            if (_address == _array[i]) return i;
        }
    }
   
    function getIndex(uint _id, uint[] memory _array) 
        internal 
        pure 
        returns (uint) 
    {
        require(_array.length > 0, 'array is empty');
        for (uint i = 0; i < _array.length; i++) {
            if (_id == _array[i]) return i;
        }
    }
}