@isTest
public class OrderTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Account acc        = TestDataFactory.createAccount('Test Account 1', 5000);
        Product2 pd        = TestDataFactory.createProduct('Chemise Verte longue XYX', 'Chemise');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pd.Id, 1020);
        Order o1           = TestDataFactory.createOrder(acc.Id, 0);
        TestDataFactory.createOrderItems(o1.Id, pbe.Id);
        // Setup : Account.Chiffre_d_affaire__c = 5 000, Order en Draft, TotalAmount = 21 500
    }

    // ───────────────────────────────────────────────────────────────
    // BEFORE UPDATE — calcul du NetAmount__c
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testBeforeUpdate_NetAmountCalculated() {
        Order o = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        o.ShipmentCost__c = 200;
        update o;
        Test.stopTest();

        Order result = [SELECT TotalAmount, ShipmentCost__c, NetAmount__c FROM Order WHERE Id = :o.Id];
        System.assertEquals(
            result.TotalAmount - result.ShipmentCost__c,
            result.NetAmount__c,
            'NetAmount__c doit être égal à TotalAmount - ShipmentCost__c'
        );
    }

    @isTest
    static void testBeforeUpdate_NetAmountWithZeroShipmentCost() {
        Order o = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        o.ShipmentCost__c = 0;
        update o;
        Test.stopTest();

        Order result = [SELECT TotalAmount, NetAmount__c FROM Order WHERE Id = :o.Id];
        System.assertEquals(
            result.TotalAmount,
            result.NetAmount__c,
            'NetAmount__c doit être égal à TotalAmount quand ShipmentCost__c est à 0'
        );
    }

    // ───────────────────────────────────────────────────────────────
    // AFTER UPDATE — Draft → Activated : CA += TotalAmount
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testAfterUpdate_DraftToActivated_IncrementeCA() {
        Account accBefore = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
        Order o = [SELECT Id, TotalAmount FROM Order LIMIT 1];

        Test.startTest();
        o.Status = 'Activated';
        update o;
        Test.stopTest();

        Account accAfter = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accBefore.Id];
        System.assertEquals(
            accBefore.Chiffre_d_affaire__c + o.TotalAmount,
            accAfter.Chiffre_d_affaire__c,
            'Draft → Activated : CA doit être incrémenté du TotalAmount'
        );
        // 5 000 + 21 500 = 26 500
        System.assertEquals(26500, accAfter.Chiffre_d_affaire__c, 'CA attendu : 26 500');
    }

    // ───────────────────────────────────────────────────────────────
    // AFTER UPDATE — Activated → Draft : CA -= TotalAmount
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testAfterUpdate_ActivatedToDraft_DecrementeCA() {
        Order o = [SELECT Id, TotalAmount FROM Order LIMIT 1];

        // On active d'abord hors Test.startTest pour établir l'état initial
        o.Status = 'Activated';
        update o;

        Account accAfterActivation = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
        // CA = 5 000 + 21 500 = 26 500

        Test.startTest();
        o.Status = 'Draft';
        update o;
        Test.stopTest();

        Account accAfter = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accAfterActivation.Id];
        System.assertEquals(
            accAfterActivation.Chiffre_d_affaire__c - o.TotalAmount,
            accAfter.Chiffre_d_affaire__c,
            'Activated → Draft : CA doit être décrémenté du TotalAmount'
        );
        // 26 500 - 21 500 = 5 000
        System.assertEquals(5000, accAfter.Chiffre_d_affaire__c, 'CA attendu : 5 000');
    }

    // ───────────────────────────────────────────────────────────────
    // AFTER UPDATE — Activated → Activated + nouvel item : CA += delta
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testAfterUpdate_ActivatedToActivated_DeltaCA() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        o.Status = 'Activated';
        update o;

        Account accAfterActivation = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
        // CA = 5 000 + 21 500 = 26 500

        Test.startTest();
        // Ajout d'un item → TotalAmount += 5 x 100 = 500 → delta = +500
        insert new OrderItem(OrderId = o.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 100);
        Test.stopTest();

        Account accAfter = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accAfterActivation.Id];
        System.assertEquals(
            accAfterActivation.Chiffre_d_affaire__c + 500,
            accAfter.Chiffre_d_affaire__c,
            'Activated → Activated : CA doit être incrémenté du seul delta de TotalAmount'
        );
        // 26 500 + 500 = 27 000
        System.assertEquals(27000, accAfter.Chiffre_d_affaire__c, 'CA attendu : 27 000');
    }

    // ───────────────────────────────────────────────────────────────
    // AFTER UPDATE — Draft → Draft : CA inchangé
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testAfterUpdate_DraftToDraft_SansImpactCA() {
        Account accBefore = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
        Order o = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        o.ShipmentCost__c = 999;
        update o;
        Test.stopTest();

        Account accAfter = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accBefore.Id];
        System.assertEquals(
            accBefore.Chiffre_d_affaire__c,
            accAfter.Chiffre_d_affaire__c,
            'Draft → Draft : aucune transition de statut, le CA ne doit pas changer'
        );
    }

    // ───────────────────────────────────────────────────────────────
    // AFTER UPDATE — Bulk : plusieurs commandes Draft → Activated
    // ───────────────────────────────────────────────────────────────

    @isTest
    static void testAfterUpdate_Bulk_DraftToActivated() {
        Account acc = [SELECT Id, Chiffre_d_affaire__c FROM Account LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        Order o2 = TestDataFactory.createOrder(acc.Id, 0);
        insert new OrderItem(OrderId = o2.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 200);
        // TotalAmount o2 = 1 000

        Account accBefore = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        List<Order> orders = [SELECT Id, TotalAmount FROM Order];
        Decimal totalMontant = 0;
        for (Order o : orders) totalMontant += o.TotalAmount;

        Test.startTest();
        for (Order o : orders) o.Status = 'Activated';
        update orders;
        Test.stopTest();

        Account accAfter = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(
            accBefore.Chiffre_d_affaire__c + totalMontant,
            accAfter.Chiffre_d_affaire__c,
            'Bulk Draft → Activated : CA doit cumuler les TotalAmount des deux commandes'
        );
        // CA avant + 21 500 (o1) + 1 000 (o2)
    }
}