global class TaskCreationOnAccountBatch implements Database.Batchable<sObject> {
    
    //User story RG-03 :
    //En tant qu’utilisateur, je veux que des tâches soient créées tous les premier lundi de chaque mois pour tous les comptes qui n’ont pas d’orders ni de tâches de rappel
    //Partie A : Contient la logique métier
    
    
    //Etape 1 : Récupérer les comptes non actifs à traiter
    global Database.QueryLocator start(Database.BatchableContext info) {  
        return Database.getQueryLocator([
            SELECT Id
            FROM Account 
            WHERE Active__c = false]);
        
    }
    
    //Etape 2 : Récupérer les tâches associés aux comptes non actifs 
    global void execute(Database.BatchableContext info, List<Account> scope) {
        
        Set<Id> AccountIdSet = (new Map<Id,SObject>(scope)).keySet();
        
        List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE WhatId IN : AccountIdSet];
        
        
        //Etape 3 : Associer les comptes et le nombre d'occurence de tâches associées dans une map  
        Map<Id,Integer> taskMap = new Map <Id,Integer>();
        for (Task tcheck : taskList){
            if (taskMap.get(tcheck.WhatId) == null) {
                taskMap.put(tcheck.WhatId,1);
            } else {
                taskMap.put(tcheck.WhatId, taskMap.get(tcheck.WhatId)+1);
            }         
        }
        
        
        //Etape 4 : Créer une tâche d'appel pour les comptes qui n'ont pas de tâches associées
        List<Task> tasksToInsert = new List<Task>();
        
        for (Account accountToCheck : scope){
            if (taskMap.get(accountToCheck.Id) == null){
                Task newTask = new Task(
                    WhatId = accountToCheck.Id, 
                    Subject = 'Call',
                    Status = 'Nouvelle',
                    Priority = 'Normale',
                    ActivityDate = Date.today().addDays(5)) ;
                
                tasksToInsert.add(newTask);
            }   
        }
        
        //Etape 5 : Insérer les nouvelles tâches dans la base de données 
        insert tasksToInsert;
    }
    
    //Etape 6 : Cloturer le batch une fois executé
    global void finish(Database.BatchableContext info) {
        System.debug('Batch terminé');
        
    }
    
    
}