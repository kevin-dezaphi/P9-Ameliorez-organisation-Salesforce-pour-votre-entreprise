@isTest
private class UpdateAllAccountsTest {

    @testSetup
    static void setup() {
        Account acc          = TestDataFactory.createAccount('Test Account 1', 5000);
        Product2 pd          = TestDataFactory.createProduct('Chemise Verte longue XYX', 'Chemise');
        PricebookEntry pbe   = TestDataFactory.createPricebookEntry(pd.Id, 1020);
        Order o1             = TestDataFactory.createOrder(acc.Id, 0);
        TestDataFactory.createOrderItems(o1.Id, pbe.Id);
    }

    @isTest
    static void testUpdateAllAccounts() {
        UpdateAllAccounts updateBatch = new UpdateAllAccounts();
        Test.startTest();
        Database.executeBatch(updateBatch);
        Test.stopTest();
    }
}