@isTest
public class UpdateAllAccountsTest {

    @TestSetup
    static void setup() {
        Product2 pd        = TestDataFactory.createProduct('Chemise Verte longue XYX', 'Chemise');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pd.Id, 1020);

        // Compte 1 — une seule commande Activated
        // TotalAmount = (10 x 150) + (20 x 1000) = 21 500
        Account acc1 = TestDataFactory.createAccount('Compte Une Commande', 0);
        Order o1 = TestDataFactory.createOrder(acc1.Id, 0);
        TestDataFactory.createOrderItems(o1.Id, pbe.Id);
        o1.Status = 'Activated';
        update o1;

        // Compte 2 — deux commandes Activated
        // TotalAmount o2 = 21 500, TotalAmount o3 = 5 x 200 = 1 000 → total = 22 500
        Account acc2 = TestDataFactory.createAccount('Compte Deux Commandes', 0);
        Order o2 = TestDataFactory.createOrder(acc2.Id, 0);
        TestDataFactory.createOrderItems(o2.Id, pbe.Id);
        o2.Status = 'Activated';
        update o2;
        Order o3 = TestDataFactory.createOrder(acc2.Id, 0);
        insert new OrderItem(OrderId = o3.Id, PricebookEntryId = pbe.Id, Quantity = 5, UnitPrice = 200);
        o3.Status = 'Activated';
        update o3;

        // Compte 3 — uniquement des commandes Draft, ne doit pas être traité par le batch
        Account acc3 = TestDataFactory.createAccount('Compte Sans Activated', 0);
        Order o4 = TestDataFactory.createOrder(acc3.Id, 0);
        TestDataFactory.createOrderItems(o4.Id, pbe.Id);
        // o4 reste en Draft

        // Compte 4 — commandes Activated ET Draft, seules les Activated comptent
        // TotalAmount o5 (Activated) = 21 500, o6 (Draft) = 21 500 ignoré
        Account acc4 = TestDataFactory.createAccount('Compte Mix Activated Draft', 0);
        Order o5 = TestDataFactory.createOrder(acc4.Id, 0);
        TestDataFactory.createOrderItems(o5.Id, pbe.Id);
        o5.Status = 'Activated';
        update o5;
        Order o6 = TestDataFactory.createOrder(acc4.Id, 0);
        TestDataFactory.createOrderItems(o6.Id, pbe.Id);
        // o6 reste en Draft
    }

    // ─────────────────────────────────────────────────────────────
    // Une seule commande Activated → Chiffre_d_affaire__c = TotalAmount
    // ─────────────────────────────────────────────────────────────
    @isTest
    static void testBatch_UneCommandeActivated() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Compte Une Commande' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        Account result = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(21500, result.Chiffre_d_affaire__c,
            'Chiffre_d_affaire__c doit être égal au TotalAmount de la seule commande Activated');
    }

    // ─────────────────────────────────────────────────────────────
    // Plusieurs commandes Activated → Chiffre_d_affaire__c = somme des TotalAmount
    // ─────────────────────────────────────────────────────────────
    @isTest
    static void testBatch_PlusieurCommandesActivated() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Compte Deux Commandes' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        Account result = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(22500, result.Chiffre_d_affaire__c,
            'Chiffre_d_affaire__c doit cumuler les TotalAmount des commandes Activated : 21 500 + 1 000 = 22 500');
    }

    // ─────────────────────────────────────────────────────────────
    // Aucune commande Activated → compte exclu du batch, Chiffre_d_affaire__c inchangé
    // ─────────────────────────────────────────────────────────────
    @isTest
    static void testBatch_AucuneCommandeActivated_CompteIgnore() {
        Account accAvant = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Compte Sans Activated' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        Account accApres = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :accAvant.Id];
        System.assertEquals(accAvant.Chiffre_d_affaire__c, accApres.Chiffre_d_affaire__c,
            'Un compte sans commande Activated ne doit pas être modifié par le batch');
    }

    // ─────────────────────────────────────────────────────────────
    // Mix Activated + Draft → seules les Activated sont comptabilisées
    // ─────────────────────────────────────────────────────────────
    @isTest
    static void testBatch_MixActivatedDraft_SeulementActivatedComptabilise() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Compte Mix Activated Draft' LIMIT 1];

        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        Account result = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(21500, result.Chiffre_d_affaire__c,
            'Seules les commandes Activated doivent être comptabilisées, pas les Draft');
    }

    // ─────────────────────────────────────────────────────────────
    // Tous les comptes traités en une passe
    // ─────────────────────────────────────────────────────────────
    @isTest
    static void testBatch_TousLesComptesTraites() {
        Test.startTest();
        Database.executeBatch(new UpdateAllAccounts());
        Test.stopTest();

        // Les 3 comptes avec au moins une commande Activated doivent avoir un CA > 0
        List<Account> comptesAvecCA = [
            SELECT Id, Name, Chiffre_d_affaire__c FROM Account
            WHERE Chiffre_d_affaire__c > 0
        ];
        System.assertEquals(3, comptesAvecCA.size(),
            'Exactement 3 comptes doivent avoir un Chiffre_d_affaire__c > 0 après le batch');

        // Le compte sans commande Activated doit rester à 0
        Account compteIgnore = [SELECT Chiffre_d_affaire__c FROM Account WHERE Name = 'Compte Sans Activated'];
        System.assertEquals(0, compteIgnore.Chiffre_d_affaire__c,
            'Le compte sans commande Activated doit rester à 0');
    }
}