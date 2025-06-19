// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TaxChain
 * @dev A blockchain-based tax management system for transparent and automated tax collection
 * @author TaxChain Development Team
 */
contract TaxChain {
    
    // State variables
    address public taxAuthority;
    uint256 public totalTaxCollected;
    uint256 public constant TAX_RATE = 10; // 10% tax rate
    
    // Structures
    struct TaxRecord {
        address taxpayer;
        uint256 income;
        uint256 taxAmount;
        uint256 timestamp;
        bool isPaid;
    }
    
    struct Taxpayer {
        string name;
        uint256 totalIncome;
        uint256 totalTaxPaid;
        bool isRegistered;
    }
    
    // Mappings
    mapping(address => Taxpayer) public taxpayers;
    mapping(uint256 => TaxRecord) public taxRecords;
    mapping(address => uint256[]) public taxpayerRecords;
    
    // Events
    event TaxpayerRegistered(address indexed taxpayer, string name);
    event TaxCalculated(address indexed taxpayer, uint256 income, uint256 taxAmount, uint256 recordId);
    event TaxPaid(address indexed taxpayer, uint256 amount, uint256 recordId);
    event TaxAuthorityChanged(address indexed oldAuthority, address indexed newAuthority);
    
    // Modifiers
    modifier onlyTaxAuthority() {
        require(msg.sender == taxAuthority, "Only tax authority can perform this action");
        _;
    }
    
    modifier onlyRegisteredTaxpayer() {
        require(taxpayers[msg.sender].isRegistered, "Taxpayer must be registered");
        _;
    }
    
    // Counter for tax records
    uint256 private recordCounter;
    
    /**
     * @dev Constructor sets the tax authority
     */
    constructor() {
        taxAuthority = msg.sender;
        recordCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new taxpayer
     * @param _name Name of the taxpayer
     */
    function registerTaxpayer(string memory _name) external {
        require(!taxpayers[msg.sender].isRegistered, "Taxpayer already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        taxpayers[msg.sender] = Taxpayer({
            name: _name,
            totalIncome: 0,
            totalTaxPaid: 0,
            isRegistered: true
        });
        
        emit TaxpayerRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Core Function 2: Calculate and record tax for declared income
     * @param _income The declared income amount
     * @return recordId The ID of the created tax record
     */
    function calculateTax(uint256 _income) external onlyRegisteredTaxpayer returns (uint256) {
        require(_income > 0, "Income must be greater than zero");
        
        uint256 taxAmount = (_income * TAX_RATE) / 100;
        recordCounter++;
        
        taxRecords[recordCounter] = TaxRecord({
            taxpayer: msg.sender,
            income: _income,
            taxAmount: taxAmount,
            timestamp: block.timestamp,
            isPaid: false
        });
        
        taxpayerRecords[msg.sender].push(recordCounter);
        taxpayers[msg.sender].totalIncome += _income;
        
        emit TaxCalculated(msg.sender, _income, taxAmount, recordCounter);
        return recordCounter;
    }
    
    /**
     * @dev Core Function 3: Pay tax for a specific record
     * @param _recordId The ID of the tax record to pay
     */
    function payTax(uint256 _recordId) external payable {
        require(_recordId > 0 && _recordId <= recordCounter, "Invalid record ID");
        
        TaxRecord storage record = taxRecords[_recordId];
        require(record.taxpayer == msg.sender, "Not authorized to pay this tax");
        require(!record.isPaid, "Tax already paid");
        require(msg.value == record.taxAmount, "Incorrect tax amount");
        
        record.isPaid = true;
        taxpayers[msg.sender].totalTaxPaid += record.taxAmount;
        totalTaxCollected += record.taxAmount;
        
        emit TaxPaid(msg.sender, record.taxAmount, _recordId);
    }
    
    /*
     * @dev Get taxpayer information
     * @param _taxpayer Address of the taxpayer
     * @return name, totalIncome, totalTaxPaid, isRegistered
     */
    function getTaxpayerInfo(address _taxpayer) external view returns (
        string memory name,
        uint256 totalIncome,
        uint256 totalTaxPaid,
        bool isRegistered
    ) {
        Taxpayer memory taxpayer = taxpayers[_taxpayer];
        return (taxpayer.name, taxpayer.totalIncome, taxpayer.totalTaxPaid, taxpayer.isRegistered);
    }
    
    /*
     * @dev Get tax record details
     * @param _recordId ID of the tax record
     * @return taxpayer, income, taxAmount, timestamp, isPaid
     */
    function getTaxRecord(uint256 _recordId) external view returns (
        address taxpayer,
        uint256 income,
        uint256 taxAmount,
        uint256 timestamp,
        bool isPaid
    ) {
        require(_recordId > 0 && _recordId <= recordCounter, "Invalid record ID");
        TaxRecord memory record = taxRecords[_recordId];
        return (record.taxpayer, record.income, record.taxAmount, record.timestamp, record.isPaid);
    }
    
    /**
     * @dev Get all tax record IDs for a taxpayer
     * @param _taxpayer Address of the taxpayer
     * @return Array of record IDs
     */
    function getTaxpayerRecords(address _taxpayer) external view returns (uint256[] memory) {
        return taxpayerRecords[_taxpayer];
    }
    
    /**
     * @dev Change tax authority (only current authority can do this)
     * @param _newAuthority Address of the new tax authority
     */
    function changeTaxAuthority(address _newAuthority) external onlyTaxAuthority {
        require(_newAuthority != address(0), "Invalid address");
        require(_newAuthority != taxAuthority, "Same authority");
        
        address oldAuthority = taxAuthority;
        taxAuthority = _newAuthority;
        
        emit TaxAuthorityChanged(oldAuthority, _newAuthority);
    }
    
    /**
     * @dev Withdraw collected taxes (only tax authority)
     * @param _amount Amount to withdraw
     */
    function withdrawTaxes(uint256 _amount) external onlyTaxAuthority {
        require(_amount <= address(this).balance, "Insufficient balance");
        require(_amount > 0, "Amount must be greater than zero");
        
        payable(taxAuthority).transfer(_amount);
    }
    
    /**
     * @dev Get contract balance
     * @return Current balance in wei
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get total number of tax records
     * @return Total record count
     */
    function getTotalRecords() external view returns (uint256) {
        return recordCounter;
    }
}
