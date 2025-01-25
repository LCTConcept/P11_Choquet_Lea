@isTest

public class TaskCreationOnAccountBatchTest {
    
    
    // Test setup communs à tous les tests
    
    @testSetup
    static void setup() {
        
        // Créer un compte avec des commandes et la case "Active" décochée
        Account accountActive = TestDataFactory.createAccount('Compte actif', true, true);
        
        // Créer un compte sans commandes et la case "Active" décochée
        Account accountNotActive = TestDataFactory.createAccount('Compte non actif', false, true);
        
        //Créer 200 comptes avec des tâches associées 
        List<Account> accountsWithTasks = TestDataFactory.createAccounts(200, true, true);
        List<Task> tasks = TestDataFactory.createTasks(accountsWithTasks, true);
        
    }
    
    
    //Test RG-03-TEST-01 : 
    // Création de tâches pour les comptes éligibles suite à l’exécution du batch 
    
    @isTest
    static void taskCreationOnApprovedAccountSuccess(){
        
        //ETANT DONNE un compte non actif sans de tâches de rappel
        
        Account inactiveAccount = [SELECT Id, Name, Active__c 
                                   FROM Account 
                                   WHERE Name = 'Compte non actif' 
                                   LIMIT 1];
        
        Integer taskCount = [SELECT COUNT() 
                             FROM Task 
                             WHERE WhatId = :inactiveAccount.Id];
        
        System.debug('Compte actif :' + inactiveAccount.Active__c  );
        System.debug('Nombre de tâches associées au compte :' + taskCount);
        
        //LORSQUE le batch s’exécute
        
        Test.startTest();
        TaskCreationOnAccountBatch batch = new TaskCreationOnAccountBatch();
        Database.executeBatch(batch,200);
        Test.stopTest();
        
        //ALORS une tâche est créée sur ce compte
        
        Account updatedAccount = [SELECT Id, Name FROM Account WHERE Id = :inactiveAccount.Id];
        Task createdTask = [SELECT Id, WhatId, Subject, Status, Priority, ActivityDate 
                            FROM Task 
                            WHERE WhatId = :inactiveAccount.Id];
        
        System.debug('Tâche associée : ' + createdTask.Subject + ' | Statut : ' + createdTask.Status + ' | Date : ' + createdTask.ActivityDate + ' | Priorité : ' + createdTask.Priority);
        
        // RESULTAT : Une tâche est créée pour le compte non actif sans de tâches de rappel avec les caractéristiques demandées
        
        System.assertEquals('Call', createdTask.Subject, 'La tâche devrait s\'appeler "Call"');
        System.assertEquals('Nouvelle', createdTask.Status, 'Le statut de la tâche devrait être "Nouvelle"');
        System.assertEquals('Normale', createdTask.Priority, 'La priorité de la tâche devrait être "Normale"');
        System.assertEquals(Date.today().addDays(5), createdTask.ActivityDate, 'La date d\'activité de la tâche devrait être dans 5 jours');
        
    }
    
    //Test RG-03-TEST-02 : 
    // Execution du batch sur un compte actif  
    
    @isTest
    static void taskCreationOnActiveAccountFail(){
        
        //ETANT DONNE un compte actif et qui n'a pas de tâches associées
        
        Account activeAccount = [SELECT Id, Name, Active__c 
                                 FROM Account 
                                 WHERE Name = 'Compte actif' 
                                 LIMIT 1];
        
        Integer taskCount = [SELECT COUNT() 
                             FROM Task 
                             WHERE WhatId = :activeAccount.Id];
        
        System.debug('Compte actif :' + activeAccount.Active__c  );
        System.debug('Nombre de tâches associées au compte :' + taskCount);
        
        //LORSQUE le batch s’exécute
        
        Test.startTest();
        TaskCreationOnAccountBatch batch = new TaskCreationOnAccountBatch();
        Database.executeBatch(batch,200);
        Test.stopTest();
        
        //ALORS aucune tâche ne s'est créée sur le compte
        
        Account updatedAccount = [SELECT Id, Name FROM Account WHERE Id = :activeAccount.Id];
        Integer updatedTaskCount = [SELECT COUNT() FROM Task  WHERE WhatId = :activeAccount.Id];
        
        System.debug('Nombre de tâches associées au compte après exécution du batch :' + updatedTaskCount);
        
        // RESULTAT : Aucune tâche n’est créée pour ce compte.
        System.assertEquals(0,updatedTaskCount,'Le compte ne devrait pas avoir de tâches associées');
        
    }
    
    //Test RG-03-TEST-03 : 
    //Execution du batch sur un compte actif avec une tâche de rappel déjà existante
    
    @isTest
    static void taskCreationOnAccountWithTaskFail(){
        
        
        //ETANT DONNE un compte non-actif avec avec au moins une tâche de rappel 
        
        Account accountNotActive = [SELECT Id, Name, Active__c 
                                    FROM Account 
                                    WHERE Name = 'Compte non actif' 
                                    LIMIT 1];
        
        Task task = TestDataFactory.createTask(accountNotActive, true);
        
        Integer taskCount = [SELECT COUNT() 
                             FROM Task 
                             WHERE WhatId = :accountNotActive.Id];
        
        System.debug('Compte actif :' + accountNotActive.Active__c  );
        System.debug('Nombre de tâches associées au compte :' + taskCount);
        
        //LORSQUE le batch s’exécute
        
        Test.startTest();
        TaskCreationOnAccountBatch batch = new TaskCreationOnAccountBatch();
        Database.executeBatch(batch,200);
        Test.stopTest();
        
        //ALORS aucune tâche ne s'est créée sur le compte
        
        Account updatedAccount = [SELECT Id, Name FROM Account WHERE Id = :accountNotActive.Id];
        Integer updatedTaskCount = [SELECT COUNT() FROM Task  WHERE WhatId = :accountNotActive.Id];
        
        System.debug('Nombre de tâches associées au compte après exécution du batch :' + updatedTaskCount);
        
        // RESULTAT : Aucune tâche n’est créée pour ce compte.
        System.assertEquals(taskCount,updatedTaskCount,' Le nombre de tâches ne doit pas avoir changé après exécution du batch');
        
        
        
    }
    
    
}