global class UpdateAllAccounts implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext info){
        //Requeter seulement les comptes qui ont au moins une commande avec le Status 'Activated'
        return Database.getQueryLocator('SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'Activated\')');

    }

    global void execute(Database.BatchableContext info, List<Account> scope) {
        Set<Id> setAccountIds = (new Map<Id,SObject>(scope)).keySet();
        List<Order> listOrders = [SELECT TotalAmount, AccountId FROM Order WHERE Status = 'Activated' AND AccountId IN :setAccountIds];

        Map<Id, Decimal> mapAccountIdToTotalAmount = new Map<Id, Decimal>();
        for (Order ord : listOrders) {
            if (!mapAccountIdToTotalAmount.containsKey(ord.AccountId)) {
                mapAccountIdToTotalAmount.put(ord.AccountId, ord.TotalAmount);
            } else {
                mapAccountIdToTotalAmount.put(ord.AccountId, mapAccountIdToTotalAmount.get(ord.AccountId) + ord.TotalAmount);
            }
        }

        List<Account> listAccToUpdate = new List<Account>();
        for (Account acc : scope) {
            acc.Chiffre_d_affaire__c = mapAccountIdToTotalAmount.get(acc.Id);
            listAccToUpdate.add(acc);
        }
        update listAccToUpdate;
    }

    global void finish(Database.BatchableContext info){

    }
 }