public without sharing class MyTeamOrdersController {
    @AuraEnabled
    public static Decimal getSumOrdersByAccount(Id accountId) {
        AggregateResult groupedResults = [SELECT SUM(TotalAmount) total FROM Order WHERE Status = 'Activated' AND AccountId = :accountId];
        return (Decimal)groupedResults.get('total');
    }
}