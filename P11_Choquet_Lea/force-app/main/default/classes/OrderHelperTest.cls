@isTest
public class OrderHelperTest {
    
    // Test setup communs à tous les tests
    
    @testSetup
    static void setup() {
        
        // Créer un produit et une entrée de prix pour les commandes
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, true);
        
        // Créer un compte avec des commandes 
        Account accountWithOrders = TestDataFactory.createAccount('Test Account w/ Commandes', false, true);
        List<Order> orders = TestDataFactory.createOrders(accountWithOrders.Id, 3, pbe, true);
        for (Order order : orders) {
            TestDataFactory.createOrderItem(order, pbe, 15, true);  // Ajouter un OrderItem avec 15 articles
            TestDataFactory.createOrderItem(order, pbe, 25, true);  // Ajouter un autre OrderItem avec 25 articles
        }   
        
        // Créer un compte sans commandes 
        Account accountWithoutOrders = TestDataFactory.createAccount('Test Account w/o Commandes', false, true);
        
    }
    
    // Test RG-02-A-TEST-01 : 
    // Activation de la case "Active" lors de l’ajout d’une commande sur un compte sans orders.
    
    @isTest 
    static void ActiveCaseCheckedAfterOrderInsertTest() {
        // ETANT DONNE qu'un compte a la case "Active" décochée et ne possède pas de commandes existantes.
        Account accountWithoutOrders = [SELECT Id, Name, Active__c 
                                        FROM Account 
                                        WHERE Name = 'Test Account w/o Commandes' 
                                        LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithoutOrders.Active__c);
        
        // LORSQUE une commande est ajoutée à ce compte
        
        Order newOrder = TestDataFactory.createOrder(accountWithoutOrders.Id, true);
        newOrder = [SELECT Id, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatus(new List<Order>{newOrder});
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
    static void ActiveCaseRectifiedAfterOrderInsertTest() {
        
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
        newOrder = [SELECT Id, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatus(new List<Order>{newOrder});
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
    static void CheckedActiveCaseUnchangedAfterOrderInsertTest() {
        
        // ETANT DONNE qu'un compte a la case "Active" cochée et des commandes associées. 
        Account accountWithOrders = [SELECT Id, Name, Active__c 
                                     FROM Account 
                                     WHERE Name = 'Test Account w/ Commandes' 
                                     LIMIT 1];
        
        System.debug('Case active avant ajout : ' + accountWithOrders.Active__c);
        
        // LORSQUE une commande est ajoutée à ce compte
        
        Order newOrder = TestDataFactory.createOrder(accountWithOrders.Id, true);
        newOrder = [SELECT Id, AccountId FROM Order WHERE Id = :newOrder.Id];
        
        Test.startTest();
        OrderHelper.updateAccountActiveStatus(new List<Order>{newOrder});
        Test.stopTest();
        
        // ALORS la case "Active" reste cochée suite à l'ajout de la commande.
        Account updatedAccount = [SELECT Id, Active__c 
                                  FROM Account 
                                  WHERE Id = :accountWithOrders.Id];
        
        System.debug('Case active après ajout : ' + updatedAccount.Active__c);
        
        //Résultat :  La case "Active" reste inchangée après l’ajout d’une commande.
        System.assertEquals(true, updatedAccount.Active__c,'La case Active__c doit être cochée après l\'ajout d\'une commande.');
        
    }
}