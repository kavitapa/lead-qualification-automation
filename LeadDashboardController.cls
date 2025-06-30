public with sharing class LeadDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> getQualifiedLeads() {
        try {
            // Check if user has access to Lead object
            if (!Schema.sObjectType.Lead.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access Lead records.');
            }
            
            return [
                SELECT Id, Name, Email, Lead_Score__c, Industry, Qualified__c, 
                       Company, Status, OwnerId, Owner.Name, CreatedDate
                FROM Lead 
                WHERE Lead_Score__c != null
                ORDER BY Lead_Score__c DESC, CreatedDate DESC
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving leads: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String assignToMe(Id leadId) {
        try {
            // Validate input
            if (leadId == null) {
                throw new AuraHandledException('Lead ID is required.');
            }
            
            // Check if user has update access to Lead
            if (!Schema.sObjectType.Lead.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update Lead records.');
            }
            
            // Query the lead with security check
            List<Lead> leads = [
                SELECT Id, Name, OwnerId, Owner.Name 
                FROM Lead 
                WHERE Id = :leadId 
                LIMIT 1
            ];
            
            if (leads.isEmpty()) {
                throw new AuraHandledException('Lead not found or you do not have access to it.');
            }
            
            Lead leadToUpdate = leads[0];
            String currentUserId = UserInfo.getUserId();
            
            // Check if already assigned to current user
            if (leadToUpdate.OwnerId == currentUserId) {
                return 'Lead is already assigned to you.';
            }
            
            // Update the lead owner
            leadToUpdate.OwnerId = currentUserId;
            update leadToUpdate;
            
            return 'Lead successfully assigned to you.';
            
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to assign lead: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning lead: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getLeadStats() {
        try {
            Map<String, Object> stats = new Map<String, Object>();
            
            // Total leads with scores
            Integer totalLeads = [
                SELECT COUNT() 
                FROM Lead 
                WHERE Lead_Score__c != null
            ];
            
            // Qualified leads
            Integer qualifiedLeads = [
                SELECT COUNT() 
                FROM Lead 
                WHERE Qualified__c = true
            ];
            
            // High score leads (>= 90)
            Integer highScoreLeads = [
                SELECT COUNT() 
                FROM Lead 
                WHERE Lead_Score__c >= 90
            ];
            
            stats.put('totalLeads', totalLeads);
            stats.put('qualifiedLeads', qualifiedLeads);
            stats.put('highScoreLeads', highScoreLeads);
            stats.put('qualificationRate', totalLeads > 0 ? (qualifiedLeads * 100 / totalLeads) : 0);
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving lead statistics: ' + e.getMessage());
        }
    }
}