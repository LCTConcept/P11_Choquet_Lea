global class TaskBatchScheduler implements Schedulable {
    
    //User story RG-03 :
    //En tant qu’utilisateur, je veux que des tâches soient créées tous les premier lundi de chaque mois pour tous les comptes qui n’ont pas d’orders ni de tâches de rappel
    //Partie B : Rendre le batch TaskCreationOnAccountBatch schedulable 
    
    
    global void execute(SchedulableContext sc) {
        
        Database.executeBatch(new TaskCreationOnAccountBatch(), 200);
    }
    
}