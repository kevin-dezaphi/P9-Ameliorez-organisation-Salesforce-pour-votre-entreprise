@isTest
public class TestDataFactory {

    public static Account createAccount(String name, Decimal chiffreAffaire) {
        Account acc = new Account(
            Name = name,
            Chiffre_d_affaire__c = chiffreAffaire
        );
        insert acc;
        return acc;
    }

    public static Product2 createProduct(String name, String family) {
        Product2 pd = new Product2(Name = name, Family = family);
        insert pd;
        return pd;
    }

    public static PricebookEntry createPricebookEntry(Id productId, Decimal unitPrice) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    public static Order createOrder(Id accountId, Decimal shipmentCost) {
        Order o = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            ShipmentCost__c = shipmentCost
        );
        insert o;
        return o;
    }

    public static List<OrderItem> createOrderItems(Id orderId, Id pricebookEntryId) {
        List<OrderItem> items = new List<OrderItem>{
            new OrderItem(OrderId = orderId, PricebookEntryId = pricebookEntryId, Quantity = 10, UnitPrice = 150),
            new OrderItem(OrderId = orderId, PricebookEntryId = pricebookEntryId, Quantity = 20, UnitPrice = 1000)
        };
        insert items;
        return items;
    }
}