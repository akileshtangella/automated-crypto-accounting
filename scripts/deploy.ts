// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { Accounting__factory, USDC__factory } from "../typechain";
import Table = require("cli-table");

async function main() {
  const signers = await ethers.getSigners();
  const stacy = signers[0];
  const shareholder = signers[1];
  const loaner = signers[2];
  const government = signers[3];
  const jugSeller = signers[4];
  const rawMaterialsSeller = signers[5];
  const alice = signers[6];

  // Deploy USDC Contract
  const USDCFactory = new USDC__factory(stacy);
  const USDC = await USDCFactory.deploy();
  await USDC.deployed();

  // Mint USDC to the various parties
  await USDC.mint(shareholder.address, 5000000);
  await USDC.mint(loaner.address, 5000000);
  await USDC.mint(alice.address, 5000000);

  async function printFinancialStatements() {
    const balanceSheetTable = new Table();
    const incomeStatementTable = new Table();
    const cashFlowStatementTable = new Table();

    balanceSheetTable.push(
      {'ASSETS': ''}, 
      {'(1) Cash': await accounting.balanceSheet('Cash')},
      {'(2) Accounts Receivable':  await accounting.balanceSheet('AccountsReceivable')},
      {'(3) Inventories': await accounting.balanceSheet('Inventories')},
      {'(4) Current Assets = (1)+(2)+(3)': await accounting.balanceSheet('CurrentAssets')},
      {'(5) Fixed Assets at Cost': await accounting.balanceSheet('FixedAssetsAtCost')},
      {'(6) Accumulated Depreciation': await accounting.balanceSheet('AccumulatedDepreciation')},
      {'(7) Net Fixed Assets = (5)-(6)': await accounting.balanceSheet('NetFixedAssets')},
      {'(8) Total Assets = (4)+(7)': await accounting.balanceSheet('TotalAssets')},
      {'': ''}, 
      {'LIABILITIES AND EQUITY': ''}, 
      {'(9) Accounts Payable': await accounting.balanceSheet('AccountsPayable')},
      {'(10) Current Portion of Debt': await accounting.balanceSheet('CurrentPortionOfDebt')},
      {'(11) Current Liabilities = (9)+(10)': await accounting.balanceSheet('CurrentLiabilities')},
      {'(12) Long-Term Debt': await accounting.balanceSheet('LongTermDebt')},
      {'(13) Capital Stock': await accounting.balanceSheet('CapitalStock')},
      {'(14) Retained Earnings': await accounting.balanceSheet('RetainedEarnings')},
      {'(15) Shareholders\' Equity = (13)-(14)': await accounting.balanceSheet('ShareholdersEquity')},
      {'(16) Total Liabilities and Equity = (11)+(12)+(15)': await accounting.balanceSheet('TotalLiabilitiesAndEquity')}
    );

    console.log(balanceSheetTable.toString());

    incomeStatementTable.push(
      {'INCOME STATEMENT': ''}, 
      {'(1) Net Sales': await accounting.incomeStatement('NetSales')},
      {'(2) Cost of Goods Sold': await accounting.incomeStatement('CostOfGoodsSold')},
      {'(3) Gross Margin = (1)-(2)': await accounting.incomeStatement('GrossMargin')},
      {'(4) General and Administrative Expenses': await accounting.incomeStatement('GeneralAndAdministrativeExpenses')},
      {'(5) Operating Expenses = (4)': await accounting.incomeStatement('OperatingExpenses')},
      {'(6) Income from Operations = (3)-(5)': await accounting.incomeStatement('IncomeFromOperations')},
      {'(7) Net Interest Income': await accounting.incomeStatement('NetInterestIncome')},
      {'(8) Income Taxes': await accounting.incomeStatement('IncomeTaxes')},
      {'(9) Net Income=(6)+(7)-(8)': await accounting.incomeStatement('NetIncome')},
    );

    console.log(incomeStatementTable.toString());

    cashFlowStatementTable.push(
      {'CASH FLOW STATEMENT': ''},
      {'(1) Beginning Cash Balance': await accounting.cashFlowStatement('BeginningCashBalance')},
      {'(2) Cash Receipts': await accounting.cashFlowStatement('CashReceipts')},
      {'(3) Cash Disbursements': await accounting.cashFlowStatement('CashDisbursements')},
      {'(4) Cash Flow from Operations = (2)-(3)': await accounting.cashFlowStatement('CashFlowFromOperations')},
      {'(5) PP&E Purchase': await accounting.cashFlowStatement('PPAndEPurchase')},
      {'(6) Net Borrowings': await accounting.cashFlowStatement('NetBorrowings')},
      {'(7) Income Taxes Paid': await accounting.cashFlowStatement('IncomeTaxesPaid')},
      {'(8) Sale of Capital Stock': await accounting.cashFlowStatement('SaleOfCapitalStock')},
      {'(9) Ending Cash Balance = (4)-(5)+(6)-(7)+(8)': await accounting.cashFlowStatement('EndingCashBalance')}
    )

    console.log(cashFlowStatementTable.toString());
  }

  console.log('Stacy Deploys the Accounting Contract');
  const accountingFactory = new Accounting__factory(stacy);
  const accounting = await accountingFactory.deploy(USDC.address, [stacy.address]);
  await accounting.deployed();
  await printFinancialStatements();

  console.log('Stacy Raises $1,000,000 of Equity from Investors');
  await USDC.connect(shareholder).approve(accounting.address, 1000000);
  await accounting.raiseEquity(shareholder.address, 1000000);
  await printFinancialStatements();

  console.log('Stacy Pays Herself $5000 in Salary');
  await accounting.paySalary(stacy.address, 5000);
  await printFinancialStatements();

  console.log('Stacy Takes a 10 Year Loan and Buys a Plot of Land for the Lemonade Stand for $50,000 at a 10% Yearly Interest Rate');
  await USDC.connect(loaner).approve(accounting.address, 50000)
  await accounting.takeLongTermDebt(loaner.address, 50000, 10);
  await printFinancialStatements();

  console.log('Stacy Buys a Jug to Make Her Lemonade In. The Total Cost is $10,000, but She Only Pays for Half Now');
  await accounting.buyFixedAsset(jugSeller.address, 10000, 5000);
  await printFinancialStatements();

  console.log('Stacy Buys Lemonade Powder and Water, the Raw Materials Needed to Make Lemonade for $500');
  await accounting.buyInventory(rawMaterialsSeller.address, 500, 500);
  await printFinancialStatements();

  console.log('Stacy Makes Lemonade and Sells All of it to Alice $20,000. She Receives Cash for Half of the Lemonade');
  await USDC.connect(alice).approve(accounting.address, 10000);
  await accounting.sellInventory(alice.address, 20000, 10000, 500);
  await printFinancialStatements();

  console.log('Stacy Pays Off the Other $5,000 She Owes for the Jug');
  await accounting.payAccountsPayable(jugSeller.address, 5000);
  await printFinancialStatements();

  console.log('Stacy Receives the Other $10,000 She is Owed From Alice');
  await USDC.connect(alice).approve(accounting.address, 10000);
  await accounting.receiveAccountsReceivable(alice.address, 10000);
  await printFinancialStatements();

  console.log('It\'s the End of the Fiscal Year. Stacy Pays the Interest She Owes on the Loan She Used to Buy the Plot of Land');
  await accounting.payInterestOnLongTermDebt(loaner.address, 5000);
  await printFinancialStatements();

  console.log('Stacy Accumulates Depreciation on Her Jug. She Uses Straight Line Depreciation Over 5 Years');
  await accounting.depreciateFixedAsset(2000);
  await printFinancialStatements();

  console.log('Stacy Pays Income Taxes at a Tax Rate of 30%');
  await accounting.payTaxes(government.address, 30);
  await printFinancialStatements();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
