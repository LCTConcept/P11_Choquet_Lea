trigger OrderTrigger on Order (after insert, before update, after delete) {
    
     // RG-01 : En tant qu’utilisateur, je veux que l’application vérifie la commande contient des bien produits avant de passer son statut en “Activated” 
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        OrderHelper.OrderStatusUpdatePrecheck(Trigger.new);
    }
    
    // RG-02-A : En tant qu’utilisateur, je veux que la case “Active” se coche automatique si le compte ne possédait pas déjà des commandes et/ou que la case est décochée. 
    
    if (Trigger.isAfter && Trigger.isInsert) {
        OrderHelper.updateAccountActiveStatusAfterInsert(Trigger.new);
    }
    
    
    // RG-02-B: En tant qu’utilisateur, je veux que l’application décoche automatiquement la case “Active” d’un compte si sa dernière commande est supprimée.  
    
    if (Trigger.isAfter && Trigger.isDelete) {
        OrderHelper.updateAccountActiveStatusAfterDelete(Trigger.old);
    }
       
}