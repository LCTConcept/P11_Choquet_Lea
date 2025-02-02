public class TaskBatchTimer {
    
    //User story RG-03 :
    //En tant qu’utilisateur, je veux que des tâches soient créées tous les premier lundi de chaque mois pour tous les comptes qui n’ont pas d’orders ni de tâches de rappel
    //Partie C : Timer du batch TaskCreationOnAccountBatch
    
    
    public static void taskCreationBatchTimer(){
        String cronExpression = '0 0 7 ? * 1#1 *'; // Premier lundi de chaque mois à 7h
        System.schedule('Création des taches sur les comptes non actifs', cronExpression, new TaskBatchScheduler());
        
    }
       
}