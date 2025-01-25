@isTest
public class TestDataFactory {
    
    // Créer un compte où la case Active est décochée par défaut. 
    public static Account createAccount(Boolean doInsert) {
        return createAccount('Test Account', false, doInsert);
    }
    
    public static Account createAccount(String name, Boolean active, Boolean doInsert) {
        Account acc = new Account(
            Name = name,
            Active__c = active);
        if (doInsert) {
            insert acc;
        }
        return acc;
    }
    
    
    // Créer une liste de comptes avec un paramètre pour Active__c
    public static List<Account> createAccounts(Integer numAccounts, Boolean activeStatus, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < numAccounts; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + (i + 1),
                Active__c = activeStatus 
            );
            accounts.add(acc);
        }
        
        // Insérer les comptes si doInsert est vrai
        if (doInsert && !accounts.isEmpty()) {
            insert accounts;
        }
        
        return accounts;
    }
    
    
    
    // Créer un produit
    public static Product2 createProduct(Boolean doInsert) {
        Product2 product = new Product2(
            Name = 'Cables Ethernet 100m', 
            IsActive = true, 
            Family = 'Consommables');
        if (doInsert) {
            insert product;
        }
        return product;
    }
    
    // Créer une entrée de prix dans le Pricebook standard
    public static PricebookEntry createPricebookEntry(Product2 product, Boolean doInsert) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 50,  
            IsActive = true
        );
        if (doInsert) {
            insert pbe;
        }
        return pbe;
    }
    
    // Créer une commande avec un statut "Draft" par défaut. 
    public static Order createOrder(Id accountId, Boolean doInsert) {
        Order ord = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()  // Utilise le Pricebook standard
        );
        if (doInsert) {
            insert ord;
        }
        return ord;
    }
    
    
    // Créer un OrderItem/OrderProduct
    public static OrderItem createOrderItem(Order order, PricebookEntry pbe, Integer quantity, Boolean doInsert) {
        OrderItem oi = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pbe.Id,
            Quantity = quantity,
            UnitPrice = pbe.UnitPrice
        );
        if (doInsert) {
            insert oi;
        }
        return oi;
    }
    
    // Créer des commandes
    public static List<Order> createOrders(Id accountId, Integer numOrders, PricebookEntry pbe, Boolean doInsert) {
        List<Order> orders = new List<Order>();
        
        for (Integer i = 1; i <= numOrders; i++) {
            // Créer une commande
            Order ord = createOrder(accountId, false);
            
            // Créer des OrderItems pour chaque commande
            OrderItem oi1 = createOrderItem(ord, pbe, 5, false); // 5 articles pour chaque OrderItem
            OrderItem oi2 = createOrderItem(ord, pbe, 10, false); // 10 articles pour chaque OrderItem
            
            orders.add(ord);
        }
        
        // Insérer les commandes et leurs items si nécessaire
        if (doInsert && !orders.isEmpty()) {
            insert orders;
        }
        
        return orders;
    }
    
    // Créer une tâche pour un compte donné
    public static Task createTask(Account account, Boolean doInsert) {
        Task task = new Task(
            WhatId = account.Id, 
            Subject = 'Call',
            Status = 'Nouvelle',
            Priority = 'Normale',
            ActivityDate = Date.today().addDays(5)
        );
        if (doInsert) {
            insert task;
        }
        return task;
    }
    
    // Créer une liste de tâches pour plusieurs comptes
    public static List<Task> createTasks(List<Account> accounts, Boolean doInsert) {
        List<Task> tasks = new List<Task>();
        
        for (Account acc : accounts) {
            tasks.add(createTask(acc, false)); // Crée une tâche pour chaque compte
        }
        
        if (doInsert && !tasks.isEmpty()) {
            insert tasks; // Insère les tâches si doInsert est vrai
        }
        
        return tasks;
    }
    
    
    
    
}