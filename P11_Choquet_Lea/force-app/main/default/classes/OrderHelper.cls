public class OrderHelper {
    
    
    //User story RG-01 : 
    //L’application vérifie que la commande contient bien des produits avant de passer son statut en “Activated”.
    
    public static void OrderStatusUpdatePrecheck(List<Order> draftOrders){
        
        //Etape 1 : Récupérer les commandes 
        Set<Id> ordersIds = new Set<Id>();
        for (Order ord : draftOrders){
            if(ord.Id != null){
                ordersIds.add(ord.Id);
            }
        }
        
        //Etape 2 : Compter les orderItems associés
        
        Map<Id,Integer> orderItemsCountMap = new Map <Id,Integer>();
        
        List<AggregateResult> orderItemCount = [
            SELECT OrderId, COUNT(Id) totalOrderItem
            FROM OrderItem
            WHERE OrderId IN : ordersIds
            GROUP BY OrderId
        ]; 
        
        for (AggregateResult result : orderItemCount){
            orderItemsCountMap.put((Id) result.get('OrderId'), (Integer) result.get('totalOrderItem'));
        }
        
        
        //Etape 3 : Application de la règle de validation = si pas de produits associés, pas de mise à jour 
        
        List<Order> ordersToUpdate = new List<Order>();
        for (Order ordToUpdate : draftOrders){
            Integer itemCount =  orderItemsCountMap.get(ordToUpdate.Id);
            if (itemCount == null || itemCount == 0) {
                ordToUpdate.addError('La commande doit contenir des produits pour passer au statut Validated.');
            } 
           
        }
           
    }
    
    //User story RG-02-A : 
    //La case “Active” se coche si le compte ne possédait pas déjà des commandes et/ou que la case est décochée. 
    
    public static void updateAccountActiveStatusAfterInsert(List<Order> newOrders) {
        
        //Étape 1 : Collecter les AccountId des commandes nouvellement insérées
        Set<Id> accountIds = new Set<Id>();
        for (Order ord : newOrders) {
            if (ord.Status != null && ord.AccountId != null) {
                accountIds.add(ord.AccountId);
            } 
        }
        
        // Étape 2 : Récupérer les comptes où Active__c est décochée
        List<Account> accountsToUpdate = [
            SELECT Id, Active__c
            FROM Account
            WHERE Id IN :accountIds AND Active__c = false
        ];
        
        // Étape 3 : Préparer la liste des comptes à mettre à jour
        for (Account acc : accountsToUpdate) {
            acc.Active__c = true;
        }
        
        // Étape 4 : Effectuer la mise à jour
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug('Erreur lors de la mise à jour des comptes : ' + e.getMessage());
            }
        }
    }
    
    //User story RG-02-B : 
    //La case “Active” se décoche automatiquement si sa dernière commande associée est supprimée. 
    
    public static void updateAccountActiveStatusAfterDelete(List<Order> oldOrders) {
        
        
        // Étape 1 : Collecter les AccountId des commandes supprimées
        Set<Id> accountIds = new Set<Id>();
        for (Order order : oldOrders) {
            if (order.AccountId != null) {
                accountIds.add(order.AccountId);
            }
        }
        
        // Étape 2 : Utiliser SOQL pour compter les commandes restantes par AccountId 
        List<AggregateResult> remainingOrderCounts = [
            SELECT AccountId, COUNT(Id) totalOrders
            FROM Order
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ];
        
        // Étape 3 : Préparer la mise à jour la de case "Active" des comptes en fonction des commandes restantes
        List<Account> accountsToUpdate = new List<Account>();
        
        Map<Id, Integer> orderCountsMap = new Map<Id, Integer>();
        for (AggregateResult result : remainingOrderCounts) {
            orderCountsMap.put((Id)result.get('AccountId'), (Integer)result.get('totalOrders'));
        }
        
        // Pour chaque accountId, vérifier si des commandes restent
        for (Id accountId : accountIds) {
            Account accToAdd = new Account(Id = accountId);
            
            // Si aucune commande ne reste, on ajoute le compte à la liste des comptes à mettre à jour
            if (!orderCountsMap.containsKey(accountId) || orderCountsMap.get(accountId) == 0) {
                accToAdd.Active__c = false;
            }        
            accountsToUpdate.add(accToAdd);
        }
        
        // Étape 4 : Étape 4 : Effectuer la mise à jour
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug('Erreur lors de la mise à jour des comptes : ' + e.getMessage());
            }
        }
        
    }       
}