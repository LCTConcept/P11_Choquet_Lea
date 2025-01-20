trigger OrderTrigger on Order (after insert, before update, before delete) {
    
    // after insert : cocher case active dans account à l'insert d'orders
    
    if (Trigger.isAfter && Trigger.isInsert) {
        OrderHelper.updateAccountActiveStatus(Trigger.new);
    }
    
    
    
    // B4 update : vérif si orders a des orders product avant de modif le statut en Activated
    /* 
* if (Trigger.isBefore && Trigger.isUpdate) {
OrderHelper.METHODE(Trigger.new);
}
*/
    
    
    // B4 delete : décocher case active dans account à la suppr de dernière order 
    /* 
* if (Trigger.isBefore && Trigger.isDelete) {
OrderHelper.METHODE(Trigger.new);
}
*/
    
}