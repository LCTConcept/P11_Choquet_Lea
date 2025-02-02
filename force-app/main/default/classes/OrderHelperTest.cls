@isTest
public class OrderHelperTest {
    
    // Test setup communs à tous les tests
    
    @testSetup
    static void setup() {
        
        // Créer un produit et une entrée de prix pour les commandes
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, true);
        
        // Créer un compte avec des commandes et la case "Active" décochée
        Account accountWithOrders = TestDataFactory.createAccount('Test Account w/ Commandes', false, true);
        List<Order> orders = TestDataFactory.createOrders(accountWithOrders.Id, 3, pbe, true);
        for (Order order : orders) {
            TestDataFactory.createOrderItem(order, pbe, 15, true);  // Ajouter un OrderItem avec 15 articles
            TestDataFactory.createOrderItem(order, pbe, 25, true);  // Ajouter un autre OrderItem avec 25 articles
        }   
        
        // Créer un compte sans commandes et la case "Active" décochée
        Account accountWithoutOrders = TestDataFactory.createAccount('Test Account w/o Commandes', false, true);
        
        
        
    }
    
    // Test RG-01-TEST-01 : 
    // Le statut de la commande passe en “Activated” car elle contient des produits
    
    @isTest 
    static void orderStatusChangeToActivatedSuccessTest(){
        
        //ETANT DONNE qu'une commande contient des produits
        
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        Order testOrder = [SELECT Id, Status, AccountId 
                           FROM Order 
                           WHERE AccountId = :accountWithOrders.Id 
                           LIMIT 1];
        
        
        System.debug('Statut de la commande avant mise à jour : ' + testOrder.Status);
        
        //LORSQUE l’utilisateur passe le statut de la commande de “Draft” à “Activated”
        
        testOrder.Status = 'Activated';
        update testOrder ;
        
        Test.startTest();
        OrderHelper.orderStatusUpdatePrecheck(new List<Order>{testOrder});
        Test.stopTest();
        
        // ALORS le statut est modifié.  
        
        Order updatedOrder = [SELECT Id, Status FROM Order WHERE Id = :testOrder.Id];
        System.debug('Statut de la commande après mise à jour : ' + updatedOrder.Status);
        
        //Résultat : le statut est passé à 'Activated'
        System.assertEquals('Activated', updatedOrder.Status, 'Le statut devrait être Activated' );
        
    }
    
    
    
    // Test RG-01-TEST-02 : 
    // Le statut de la commande ne passe PAS en “Activated” car elle ne contient pas de produits
    
    @isTest 
    static void orderStatusChangeToActivatedFailTest(){
        
        //ETANT DONNE qu'une commande ne contient PAS de produits
        
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        
        Order emptyOrder = TestDataFactory.createOrder(accountWithOrders.Id, true);
        
        System.debug('Statut de la commande avant mise à jour : ' + emptyOrder.Status);
        
        //LORSQUE l’utilisateur passe le statut de la commande de “Draft” à “Activated”
        
        emptyOrder.Status = 'Activated';
        try{
            update emptyOrder ;
        } catch (DmlException e) {
            System.debug('Erreur lors de l\'insertion de la commande : ' + e.getMessage());
        }
        
        
        Test.startTest();
        OrderHelper.orderStatusUpdatePrecheck(new List<Order>{emptyOrder});
        Test.stopTest();
        
        // ALORS le statut reste en Draft.   
        
        Order updatedOrder = [SELECT Id, Status FROM Order WHERE Id = :emptyOrder.Id];
        System.debug('Statut de la commande après mise à jour : ' + updatedOrder.Status);
        
        //Résultat : le statut est passé à 'Activated'
        System.assertEquals('Draft', updatedOrder.Status, 'Le statut devrait toujours être en Draft' );
        
        
    }
    
    
    
    
    // Test RG-02-A-TEST-01 : 
    // Activation de la case "Active" lors de l’ajout d’une commande sur un compte sans orders.
    
    @isTest 
    static void activeCaseCheckedAfterOrderInsertTest() {
        // ETANT DONNE qu'un compte a la case "Active" décochée et ne possède pas de commandes existantes.
        Account accountWithoutOrders = [SELECT Id, Name, Active__c 
                                        FROM Account 
                                        WHERE Name = 'Test Account w/o Commandes' 
                                        LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithoutOrders.Active__c);
        
        // LORSQUE une commande est ajoutée à ce compte
        
        Order newOrder = TestDataFactory.createOrder(accountWithoutOrders.Id, true);
        newOrder = [SELECT Id, Status, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatusAfterInsert(new List<Order>{newOrder});
        Test.stopTest();
        
        // ALORS la case "Active" est cochée automatiquement suite à l'ajout de la commande.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithoutOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        //Résultat : La case "Active" doit être cochée après l’ajout. 
        System.assertEquals(true, updatedAccount.Active__c,'La case Active__c doit être cochée après l\'ajout d\'une commande.');
    }
    
    // Test RG-02-A-TEST-02 : 
    // Activation de la case "Active" lors de l’ajout d’une commande sur un compte avec des orders dont la case est décochée.
    
    @isTest 
    static void activeCaseRectifiedAfterOrderInsertTest() {
        
        // ETANT DONNE qu'un compte a la case "Active" décochée malgré des commandes associées. 
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        System.debug('Case active avant modif : ' + accountWithOrders.Active__c);
        accountWithOrders.Active__c = false;
        update accountWithOrders; 
        System.debug('Case active après modif mais avant ajout : ' + accountWithOrders.Active__c);
        
        // LORSQUE une commande est ajoutée à ce compte
        
        Order newOrder = TestDataFactory.createOrder(accountWithOrders.Id, true);
        newOrder = [SELECT Id, Status, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatusAfterInsert(new List<Order>{newOrder});
        Test.stopTest();
        
        // ALORS la case "Active" est cochée automatiquement suite à l'ajout de la commande.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        //Résultat : La case "Active" doit être cochée après l’ajout. 
        System.assertEquals(true, updatedAccount.Active__c,'La case Active__c doit être cochée après l\'ajout d\'une commande.');
        
    }
    
    // Test RG-02-A-TEST-03 : 
    // Pas de changement de la case "Active" lors de l’ajout d’une commande sur un compte avec des orders dont la case est cochée.
    
    @isTest 
    static void checkedActiveCaseUnchangedAfterOrderInsertTest() {
        
        // ETANT DONNE qu'un compte a la case "Active" cochée et des commandes associées
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithOrders.Active__c);
        
        // LORSQUE une commande est ajoutée à ce compte
        
        Order newOrder = TestDataFactory.createOrder(accountWithOrders.Id, true);
        newOrder = [SELECT Id, Status, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatusAfterInsert(new List<Order>{newOrder});
        Test.stopTest();
        
        // ALORS la case "Active" reste cochée suite à l'ajout de la commande.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        //Résultat :  La case "Active" reste inchangée après l’ajout d’une commande.
        System.assertEquals(true, updatedAccount.Active__c,'La case Active__c doit être cochée après l\'ajout d\'une commande.');
        
    }
    
    
    // Test RG-02-A-TEST-04 : 
    // Activation de la case "Active" lors de l’ajout d’une commande au statut 'Activated' sur un compte sans orders.
    @isTest 
    static void activeCaseCheckedAfterActivatedOrderInsertTest() {
        
        // ETANT DONNE qu'un compte a la case "Active" décochée et ne possède pas de commandes existantes.
        Account accountWithoutOrders = [SELECT Id, Name, Active__c 
                                        FROM Account 
                                        WHERE Name = 'Test Account w/o Commandes' 
                                        LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithoutOrders.Active__c);
        
        // LORSQUE une commande au statut "Activated" est ajoutée à ce compte
        
        PricebookEntry pbe = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice 
                              FROM PricebookEntry 
                              WHERE Pricebook2Id = :Test.getStandardPricebookId() 
                              LIMIT 1];
        
        Order newOrder = TestDataFactory.createOrder(accountWithoutOrders.Id, true);
        newOrder = [SELECT Id, Status, AccountId FROM Order WHERE Id = :newOrder.Id];
        TestDataFactory.createOrderItem(newOrder, pbe, 15, true);  // Ajouter un OrderItem avec 15 articles
        TestDataFactory.createOrderItem(newOrder, pbe, 25, true);  // Ajouter un autre OrderItem avec 25 articles
        
        
        System.debug('Statut de la commande avant modif : ' + newOrder.Status);
        newOrder.Status = 'Activated';
        update newOrder;
        
        System.debug('Statut de la commande après modif : ' + newOrder.Status);
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatusAfterInsert(new List<Order>{newOrder});
        Test.stopTest();
        
        // ALORS la case "Active" est cochée automatiquement suite à l'ajout de la commande.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithoutOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        // Résultat : La case "Active" doit être cochée après l’ajout. 
        System.assertEquals(true, updatedAccount.Active__c, 'La case Active__c doit être cochée après l\'ajout d\'une commande avec statut Activated.');
    }
    
    // Test RG-02-A-TEST-05 : 
    // La mise à jour de la case ne fonctionne pas en raison d’une erreur 
    
    @isTest
    static void updateAccountFailsTest(){
        
        // ETANT DONNE qu'un compte a la case "Active" décochée et ne possède pas de commandes existantes.
        Account accountWithoutOrders = [SELECT Id, Name, Active__c 
                                        FROM Account 
                                        WHERE Name = 'Test Account w/o Commandes' 
                                        LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithoutOrders.Active__c);
        
        // LORSQUE une commande au statut null est ajoutée à ce compte et déclenche une erreur
        
        Order invalidOrder = new Order(
            AccountId = accountWithoutOrders.Id,
            EffectiveDate = Date.today()
            // Status n'est pas défini
        );
        
        System.debug('Statut de la commande avant insertion : ' + invalidOrder.Status);
        
        Test.startTest();
        try {
            insert invalidOrder;
        } catch (DmlException e) {
            System.debug('Erreur lors de l\'insertion de la commande avec statut manquant : ' + e.getMessage());
        }
        Test.stopTest();
        
        // ALORS la case "Active" reste décochée.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithoutOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        // Résultat : La case "Active" ne doit PAS être cochée après l’ajout. 
        System.assertEquals(false, updatedAccount.Active__c, 'La case Active__c doit être cochée après l\'ajout d\'une commande avec statut Activated.');
    }
    
    
    
    // Test RG-02-B-TEST-01 : 
    // Désactivation de la case "Active" lorsqu'il n'y a plus de commandes associées après une suppression.
    
    @isTest 
    
    static void activeCaseUncheckedAfterLastOrderDeletedTest() {
        // ETANT DONNE qu'un compte a la case "Active" cochée et possède des commandes existantes.
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        System.debug('Case active avant suppression : ' + accountWithOrders.Active__c);
        
        // Récupérer toutes les commandes associées au compte
        List<Order> accountOrders = [SELECT Id, AccountId 
                                     FROM Order 
                                     WHERE AccountId = :accountWithOrders.Id];
        
        System.debug('Nombre de commandes avant suppression : ' + accountOrders.size());
        
        // LORSQUE la dernière commande associée au compte est supprimée
        Test.startTest();
        delete accountOrders;
        Test.stopTest();
        
        
        // Vérifier le nombre de commandes après suppression
        accountOrders = [SELECT Id, AccountId 
                         FROM Order 
                         WHERE AccountId = :accountWithOrders.Id];  
        System.debug('Nombre de commandes après suppression : ' + accountOrders.size());  
        
        // ALORS la case "Active" est décochée automatiquement suite à la suppression de toutes les commandes.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithOrders.Id];
        
        
        System.debug('Case active après suppression : ' + updatedAccount.Active__c);
        
        // Résultat : La case "Active" doit être décochée après la suppression de la dernière commande.
        System.assertEquals(false, updatedAccount.Active__c, 'La case Active__c doit être décochée après la suppression de la dernière commande associée.');
    }
    
    // Test RG-02-B-TEST-02 : 
    //  S’il reste des commandes sur ce compte après la suppression, la case “Active” du compte reste cochée. 
    
    @isTest 
    
    static void checkedActiveCaseUnchangedAfterOrderDeletedTest() {
        // ETANT DONNE qu’un compte est déjà actif et qu’il a au moins deux  commandes
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        System.debug('Case active avant suppression : ' + accountWithOrders.Active__c);
        
        // Récupérer toutes les commandes associées au compte
        List<Order> accountOrders = [SELECT Id, AccountId 
                                     FROM Order 
                                     WHERE AccountId = :accountWithOrders.Id];
        
        System.debug('Nombre de commandes avant suppression : ' + accountOrders.size());
        
        // LORSQUE la dernière commande associée au compte est supprimée
        Test.startTest();
        delete accountOrders[0];
        Test.stopTest();
        
        
        // Vérifier le nombre de commandes après suppression
        accountOrders = [SELECT Id, AccountId 
                         FROM Order 
                         WHERE AccountId = :accountWithOrders.Id];  
        System.debug('Nombre de commandes après suppression : ' + accountOrders.size());  
        
        // ALORS la case "Active" est décochée automatiquement suite à la suppression de toutes les commandes.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithOrders.Id];
        
        
        System.debug('Case active après suppression : ' + updatedAccount.Active__c);
        
        // Résultat : La case "Active" doit être encore cochée après la suppression d'une commande et qu'il en reste d'autres associées.
        System.assertEquals(true, updatedAccount.Active__c, 'La case Active__c doit être cochée après la suppression d\'une commande associée tant qu\'il y en a d\'autres.');
    } 
}