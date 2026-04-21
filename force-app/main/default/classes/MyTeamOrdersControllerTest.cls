@isTest
public class MyTeamOrdersControllerTest {

    @TestSetup
    static void setup() {
        Account acc        = TestDataFactory.createAccount('Test Account 1', 0);
        Product2 pd        = TestDataFactory.createProduct('Chemise Verte longue XYX', 'Chemise');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pd.Id, 1020);

        // Commande Activated — TotalAmount = (10 x 150) + (20 x 1000) = 21 500
        Order o1 = TestDataFactory.createOrder(acc.Id, 0);
        TestDataFactory.createOrderItems(o1.Id, pbe.Id);
        o1.Status = 'Activated';
        update o1;

        // Commande Draft — ne doit pas être comptabilisée
        Order o2 = TestDataFactory.createOrder(acc.Id, 0);
        TestDataFactory.createOrderItems(o2.Id, pbe.Id);
    }

    @isTest
    static void testGetSumOrdersByAccount_AvecCommandesActivees() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // Seule o1 (Activated) est comptabilisée : 21 500
        System.assertEquals(21500, result,
            'La somme doit inclure uniquement les commandes Activated');
    }

    @isTest
    static void testGetSumOrdersByAccount_SansCommandeActivee() {
        // Nouveau compte sans aucune commande Activated
        Account accVide = TestDataFactory.createAccount('Test Account Vide', 0);

        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(accVide.Id);
        Test.stopTest();

        // SUM sur zéro ligne renvoie null
        System.assertEquals(null, result,
            'La somme doit être null si aucune commande Activated');
    }

    @isTest
    static void testGetSumOrdersByAccount_PlusieursCommandesActivees() {
        Account acc        = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // On active o2 et on ajoute une 3ème commande Activated — TotalAmount = 5 x 200 = 1 000
        Order o2 = [SELECT Id FROM Order WHERE Status = 'Draft' LIMIT 1];
        o2.Status = 'Activated';
        update o2;

        Order o3 = TestDataFactory.createOrder(acc.Id, 0);
        insert new OrderItem(OrderId = o3.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 200);
        o3.Status = 'Activated';
        update o3;

        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // o1 (21 500) + o2 (21 500) + o3 (1 000) = 44 000
        System.assertEquals(44000, result,
            'La somme doit cumuler toutes les commandes Activated du compte');
    }

    @isTest
    static void testGetSumOrdersByAccount_CommandeAutreCompte() {
        Account acc        = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Commande Activated sur un autre compte — ne doit pas impacter acc
        Account autreAcc = TestDataFactory.createAccount('Autre Account', 0);
        Order o = TestDataFactory.createOrder(autreAcc.Id, 0);
        insert new OrderItem(OrderId = o.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 500);
        o.Status = 'Activated';
        update o;

        Test.startTest();
        Decimal result = MyTeamOrdersController.getSumOrdersByAccount(acc.Id);
        Test.stopTest();

        // Seule o1 du compte principal est Activated : 21 500
        System.assertEquals(21500, result,
            'La somme ne doit pas inclure les commandes des autres comptes');
    }
}