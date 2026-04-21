public with sharing class OrderTriggerHandler {
    public static void handleTrigger(List<Order> newOrders, List<Order> oldOrders, System.TriggerOperation triggerOperation) {
        if (triggerOperation == System.TriggerOperation.BEFORE_UPDATE) {
            for (Order newOrder: newOrders) {
                newOrder.NetAmount__c = newOrder.TotalAmount - newOrder.ShipmentCost__c;
            }
        }

        if (triggerOperation == System.TriggerOperation.AFTER_UPDATE) {
            Map<Id, Order> mapOldOrders = new Map<Id, Order>();
            for (Order oldOrder: oldOrders) {
                mapOldOrders.put(oldOrder.Id, oldOrder);
            }

            Map<Id, Decimal> mapAccountIdToOder = new Map<Id, Decimal>();
            for (Order newOrder: newOrders) {
                Order oldOrder = mapOldOrders.get(newOrder.Id);

                Decimal deltaTotalAmount = 0;
                if (oldOrder.Status != 'Activated' && newOrder.Status == 'Activated') {
                    deltaTotalAmount = newOrder.TotalAmount; // Si le statut passe de non-activé à activé, on ajoute le TotalAmount
                } else if (oldOrder.Status == 'Activated' && newOrder.Status != 'Activated') {
                    deltaTotalAmount = -oldOrder.TotalAmount; // Si le statut passe d'activé à non-activé, on soustrait le TotalAmount
                }

                if (deltaTotalAmount == 0) {
                    continue; // Si le TotalAmount n'a pas changé, on ne fait rien
                }

                if (!mapAccountIdToOder.containsKey(newOrder.AccountId)) {
                    mapAccountIdToOder.put(newOrder.AccountId, deltaTotalAmount);
                } else {
                    mapAccountIdToOder.put(newOrder.AccountId, mapAccountIdToOder.get(newOrder.AccountId) + deltaTotalAmount);
                }
            }

            List<Account> listAccToUpdate = new List<Account>();
            List<Account> listAcc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :mapAccountIdToOder.keySet()];
            for (Account acc : listAcc) {
                acc.Chiffre_d_affaire__c += mapAccountIdToOder.get(acc.Id);
                listAccToUpdate.add(acc);
            }
            update listAccToUpdate;
        }
    }
}