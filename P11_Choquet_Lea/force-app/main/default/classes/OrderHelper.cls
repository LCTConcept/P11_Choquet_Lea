public class OrderHelper {
    
    //Contient la logique des triggers 
    
    
    //1. User story RG-02-A : 
    //La case “Active” se coche si le compte ne possédait pas déjà des commandes et/ou que la case est décochée. 
    
    public static void updateAccountActiveStatus(List<Order> newOrders) {
        
        //Étape 1 : Collecter les AccountId des commandes nouvellement insérées
        Set<Id> accountIds = new Set<Id>();
        for (Order ord : newOrders) {
            if (ord.AccountId != null) {
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
    
    
    
    
    //2. vérif si orders a des orders product avant de modif le statut en Activated
    
    
    
    
    //3. décocher case active dans account à la suppr de dernière order 
    
    
    
    
}