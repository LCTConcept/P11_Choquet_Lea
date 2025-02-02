@isTest

public class TaskCreationOnAccountBatchTest {
    
    
    // Test setup communs à tous les tests
    
    @testSetup
    static void setup() {
        
        // Créer un compte avec des commandes et la case "Active" décochée
        Account accountActive = TestDataFactory.createAccount('Compte actif', true, true);
        
        // Créer un compte sans commandes et la case "Active" décochée
        Account accountNotActive = TestDataFactory.createAccount('Compte non actif', false, true);
        
        //Créer 150 comptes inactifs sans tâches associées
        List<Account> accountsWithTasks = TestDataFactory.createAccounts(150, false, true);
        
    }
    
    
    //Test RG-03-TEST-01 : 
    // Création de tâches pour les comptes éligibles suite à l’exécution du batch 
    
    @isTest
    static void taskCreationOnApprovedAccountSuccessTest(){
        
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
    static void taskCreationOnActiveAccountFailTest(){
        
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
    static void taskCreationOnAccountWithTasksFailTest(){
        
        
        //ETANT DONNE un compte non-actif avec avec 5 tâches de rappel 
        
        Account accountNotActive = [SELECT Id, Name, Active__c 
                                    FROM Account 
                                    WHERE Name = 'Compte non actif' 
                                    LIMIT 1];
        
        for (Integer i = 0; i < 5; i++) {
            Task task = TestDataFactory.createTask(accountNotActive, true); 
        }
        
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
    
    //Test RG-03-TEST-04 : 
    //Execution du batch scheduler   
    
    
    @isTest
    static void batchTimerExecutionSuccessTest() {
        
        // ETANT DONNE un compte non actif sans de tâches de rappel 
        Account inactiveAccount = [SELECT Id, Name, Active__c 
                                   FROM Account 
                                   WHERE Name = 'Compte non actif' 
                                   LIMIT 1];
        
        Integer taskCount = [SELECT COUNT() 
                             FROM Task 
                             WHERE WhatId = :inactiveAccount.Id];
        
        System.debug('Nom du compte :' + inactiveAccount.Name + ' - Compte actif :' + inactiveAccount.Active__c);
        System.debug('Nombre de tâches associées au compte :' + taskCount);
        
        CronTrigger[] scheduledJobBefore = [SELECT Id, CronExpression, NextFireTime FROM CronTrigger];
        System.debug('Nombre de batch prévus avant la planification : ' + scheduledJobBefore.size());
        
        // LORSQUE le batch est planifié via TaskBatchTimer
        Test.startTest();
        TaskBatchTimer.taskCreationBatchTimer(); 
        Test.stopTest();
        
        // ALORS le batch est bien pris en compte dans la liste des batch à exécuter
        CronTrigger[] scheduledJobAfter = [SELECT Id, CronExpression, NextFireTime FROM CronTrigger];
        System.debug('Nombre de batch prévus après la planification: ' + scheduledJobAfter.size());
        
        // RESULTAT: il devrait y avoir 1 job de plus après l'appel de TaskCreationBatchTimer
        System.assertEquals(scheduledJobBefore.size() + 1, scheduledJobAfter.size(), 'Il devrait y avoir 1 batch prévu supplémentaire après la planification.');
        
    }
    
    
    //Test RG-03-TEST-05 : 
    // Création de tâches pour 150 comptes éligibles suite à l’exécution du batch 
    
    @isTest
    static void taskCreationOnMultipleAccountsSuccessTest(){
        
        //ETANT DONNE 150 comptes non actifs sans de tâches de rappel
        
        List<Account> accountsToUpdate = [SELECT Id, Name, Active__c 
                                          FROM Account 
                                          WHERE Name LIKE 'Test Account%' 
                                          AND Active__c = false 
                                          LIMIT 150];
        
        Integer taskCountBefore = [SELECT COUNT() 
                                   FROM Task 
                                   WHERE WhatId IN :accountsToUpdate];
        
        System.debug('Nombre de comptes :' + accountsToUpdate.size() );
        System.debug('Nombre de tâches associées aux comptes avant le batch:' + taskCountBefore);
        
        //LORSQUE le batch s’exécute
        
        Test.startTest();
        TaskCreationOnAccountBatch batch = new TaskCreationOnAccountBatch();
        Database.executeBatch(batch,200);
        Test.stopTest();
        
        //ALORS une tâche s'est créée pour chaque compte
        
        List<Account> accountsUpdated  = [SELECT Id, Name, Active__c 
                                          FROM Account 
                                          WHERE Name  LIKE 'Test Account%' 
                                          LIMIT 150];
        Integer updatedTaskCount = [SELECT COUNT() FROM Task  WHERE WhatId = :accountsUpdated];
        
        System.debug('Nombre de tâches associées aux comptes après le batch:' + updatedTaskCount);
        
        // RESULTAT : Le batch s'est exécuté correctement et une tâche s'est créée pour chaque compte
        System.assertEquals(150,updatedTaskCount,' Il doit y avoir 150 tâches en tout : une pour chaque compte');
        
    }
    
    
}