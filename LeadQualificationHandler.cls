public class LeadQualificationHandler {
    public static void handleBefore(List<Lead> leads) {
        for (Lead l : leads) {
            Integer score = LeadScoringHelper.calculateScore(l);
            l.Lead_Score__c = score;
            l.Qualified__c = score > 80;
        }
    }

    public static void handleAfter(List<Lead> leads) {
        List<Task> tasksToInsert = new List<Task>();

        for (Lead l : leads) {
            if (l.Qualified__c == true) {
                tasksToInsert.add(new Task(
                    Subject = 'Follow up on Qualified Lead',
                    WhoId  = l.Id,
                    OwnerId = l.OwnerId,
                    Status = 'Not Started'
                ));
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}