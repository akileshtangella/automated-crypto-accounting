// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Accounting {

    mapping (string => int256) public balanceSheet;
    mapping (string => int256) public incomeStatement;
    mapping (string => int256) public cashFlowStatement;

    // Set of addresses that can conduct business on behalf of the company
    mapping (address => bool) private admins;

    // usdc Contract
    address public usdc;

    // The constructor initializes the admins mapping
    constructor (address _usdc, address[] memory _adminArray) {
        for(uint i = 0; i < _adminArray.length; i++) {
            admins[_adminArray[i]] = true;
        }

        usdc = _usdc;
    }

    // Function modifier which checks whether the caller of a function is part of the admin set
    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller not part of the admin set");
        _;
    }

    function raiseEquity(address shareholder, int256 equityAmount) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] += equityAmount;
        balanceSheet["CapitalStock"] += equityAmount;
        calculateBalanceSheetTotals();

        // No Updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["SaleOfCapitalStock"] += equityAmount;
        calculateCashFlowStatementTotals();

        // Receive the funds 
        IERC20(usdc).transferFrom(shareholder, address(this), uint256(equityAmount));

    }

    /**
     */
    function paySalary(address employee, int256 salary) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] -= salary;
        balanceSheet["RetainedEarnings"] -= salary;
        calculateBalanceSheetTotals();

        // Updates to Income Statement
        incomeStatement["GeneralAndAdministrativeExpenses"] += salary;
        calculateIncomeStatementTotals();

        // Updates to Cash Flow Statement
        cashFlowStatement["CashDisbursements"] += salary;
        calculateCashFlowStatementTotals();

        // Pay the employee
        IERC20(usdc).transfer(employee, uint256(salary));
    }

    /**
     */
    function takeLongTermDebt(address loaner, int256 loanAmount, int8 interestRate) external onlyAdmin {
        require(interestRate <= 100, "Not a valid interest rate");

        int256 currentPortionOfDebt = loanAmount * interestRate / 100;
        // Updates to Balance Sheet
        balanceSheet["Cash"] += loanAmount;
        balanceSheet["LongTermDebt"] += loanAmount - currentPortionOfDebt;
        balanceSheet["CurrentPortionOfDebt"] += currentPortionOfDebt;
        calculateBalanceSheetTotals();

        // No Updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["NetBorrowings"] += loanAmount;
        calculateCashFlowStatementTotals();

        // Receive Funds from Loaner
        IERC20(usdc).transferFrom(loaner, address(this), uint256(loanAmount));
    }

    /**
     */
    function payInterestOnLongTermDebt(address loaner, int256 interestAmount) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] -= interestAmount;
        balanceSheet["RetainedEarnings"] -= interestAmount;
        calculateBalanceSheetTotals();

        // Updates to Income Statement
        incomeStatement["NetInterestIncome"] -= interestAmount;
        calculateIncomeStatementTotals();

        // Updates to Cash Flow Statement
        cashFlowStatement["CashDisbursements"] += interestAmount;
        calculateCashFlowStatementTotals();

        // Pay Loaner
        IERC20(usdc).transfer(loaner, uint256(interestAmount));
    }


    /**
     */
    function buyFixedAsset(address recipient, int256 fixedAssetCost, int256 amountToPayNow) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["FixedAssetsAtCost"] += fixedAssetCost;
        balanceSheet["Cash"] -= amountToPayNow;
        balanceSheet["AccountsPayable"] += fixedAssetCost - amountToPayNow;
        calculateBalanceSheetTotals();

        // No Updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["PPAndEPurchase"] += amountToPayNow;
        calculateCashFlowStatementTotals();

        // Make Payment for the Fixed Asset
        IERC20(usdc).transfer(recipient, uint256(fixedAssetCost));
    }

    /**
     */
    function depreciateFixedAsset(int256 depreciation) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["AccumulatedDepreciation"] += depreciation;
        balanceSheet["Inventories"] += depreciation;
        calculateBalanceSheetTotals();

        // No updates to Income Statement
        // No updates to Cash Flow Statement
    }

    /**
     */
    function buyInventory(address seller, int256 cost, int256 amountToPayNow) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] -= amountToPayNow;
        balanceSheet["Inventories"] += cost;
        balanceSheet["AccountsPayable"] += cost - amountToPayNow;
        calculateBalanceSheetTotals();

        // No updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["CashDisbursements"] += amountToPayNow;
        calculateCashFlowStatementTotals();

        // Pay the seller
        IERC20(usdc).transfer(seller, uint256(amountToPayNow));
    }

    /**
     */
    function sellInventory(address buyer, int256 revenueFromSale, int256 amountToReceiveNow, int256 costOfGoodsSold) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] += amountToReceiveNow;
        balanceSheet["AccountsReceivable"] += revenueFromSale - amountToReceiveNow;
        balanceSheet["Inventories"] -= costOfGoodsSold;
        balanceSheet["RetainedEarnings"] += revenueFromSale - costOfGoodsSold;
        calculateBalanceSheetTotals();

        // Updates to Income Statement
        incomeStatement["NetSales"
        ] += revenueFromSale;
        incomeStatement["CostOfGoodsSold"] += costOfGoodsSold;
        calculateIncomeStatementTotals();

        // Updates to Cash Flow Statement
        cashFlowStatement["CashReceipts"] += amountToReceiveNow;
        calculateCashFlowStatementTotals();

        // Receive Funds from Buyer
        IERC20(usdc).transferFrom(buyer, address(this), uint256(amountToReceiveNow));
    }

    /**
     */
    function payAccountsPayable(address owed, int256 amountToPay) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] -= amountToPay;
        balanceSheet["AccountsPayable"] -= amountToPay;
        calculateBalanceSheetTotals();

        // No updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["CashDisbursements"] += amountToPay;
        calculateCashFlowStatementTotals();

        // Pay the owed party
        IERC20(usdc).transfer(owed, uint256(amountToPay));
    }

    /**
     */
    function receiveAccountsReceivable(address ower, int256 amountToReceive) external onlyAdmin {
        // Updates to Balance Sheet
        balanceSheet["Cash"] += amountToReceive;
        balanceSheet["AccountsReceivable"] -= amountToReceive;
        calculateBalanceSheetTotals();
        
        // No Updates to Income Statement
        // Updates to Cash Flow Statement
        cashFlowStatement["CashReceipts"] += amountToReceive;
        calculateCashFlowStatementTotals();

        // Receive cash from the ower
        IERC20(usdc).transferFrom(ower, address(this), uint256(amountToReceive));
    }

    /**
     */
    function payTaxes(address government, int8 taxRate) external onlyAdmin {
        require(taxRate <= 100, "Not a valid tax rate");
        int256 taxAmount = incomeStatement["IncomeFromOperations"] * taxRate / 100;

        // Updates to Balance Sheet
        balanceSheet["Cash"] -= taxAmount;
        balanceSheet["RetainedEarnings"] -= taxAmount;
        calculateBalanceSheetTotals();

        // Updates to Income Statement
        incomeStatement["IncomeTaxes"] += taxAmount;
        calculateIncomeStatementTotals();

        // Updates to Cash Flow Statement
        cashFlowStatement["IncomeTaxesPaid"] += taxAmount;
        calculateCashFlowStatementTotals();

        // Pay Taxes
        IERC20(usdc).transfer(government, uint256(taxAmount));
    }

    function calculateBalanceSheetTotals() public {
        balanceSheet["CurrentAssets"] = balanceSheet["Cash"] + balanceSheet["AccountsReceivable"] + balanceSheet["Inventories"];

        balanceSheet["NetFixedAssets"] = balanceSheet["FixedAssetsAtCost"] - balanceSheet["AccumulatedDepreciation"];

        balanceSheet["TotalAssets"] = balanceSheet["CurrentAssets"] + balanceSheet["NetFixedAssets"];

        balanceSheet["CurrentLiabilities"] = balanceSheet["AccountsPayable"] + balanceSheet["CurrentPortionOfDebt"];

        balanceSheet["ShareholdersEquity"] = balanceSheet["CapitalStock"] + balanceSheet["RetainedEarnings"];

        balanceSheet["TotalLiabilitiesAndEquity"] = balanceSheet["CurrentLiabilities"] + balanceSheet["LongTermDebt"] + balanceSheet["ShareholdersEquity"];
    }

    function calculateIncomeStatementTotals() public {
         incomeStatement["GrossMargin"] = incomeStatement["NetSales"] - incomeStatement["CostOfGoodsSold"];

        incomeStatement["OperatingExpenses"] = incomeStatement["GeneralAndAdministrativeExpenses"];

        incomeStatement["IncomeFromOperations"] = incomeStatement["GrossMargin"] - incomeStatement["OperatingExpenses"];

        incomeStatement["NetIncome"] = incomeStatement["IncomeFromOperations"] + incomeStatement["NetInterestIncome"] - incomeStatement["IncomeTaxes"];
    }

    function calculateCashFlowStatementTotals() public {
        cashFlowStatement["CashFlowFromOperations"] = cashFlowStatement["CashReceipts"] - cashFlowStatement["CashDisbursements"];

        cashFlowStatement["EndingCashBalance"] = cashFlowStatement["BeginningCashBalance"] + cashFlowStatement["CashFlowFromOperations"] - cashFlowStatement["PPAndEPurchase"] + cashFlowStatement["NetBorrowings"] - cashFlowStatement["IncomeTaxesPaid"] + cashFlowStatement["SaleOfCapitalStock"];
    }
}