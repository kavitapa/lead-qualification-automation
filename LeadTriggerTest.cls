@isTest
private class LeadTriggerTest {
    
    @isTest 
    static void testHighScoreLeadQualification() {
        // Test high-scoring lead that should be qualified
        Lead highScoreLead = new Lead(
            LastName = 'HighScore',
            Company = 'Tech Corp',
            Industry = 'Technology',
            Company_Size__c = 'Large',
            AnnualRevenue = 6000000,
            Email = 'ceo@enterprise.com',
            Country = 'USA'
        );
        
        Test.startTest();
        insert highScoreLead;
        Test.stopTest();
        
        Lead result = [SELECT Lead_Score__c, Qualified__c FROM Lead WHERE Id = :highScoreLead.Id];
        System.assert(result.Lead_Score__c > 80, 'High score lead should have score > 80');
        System.assert(result.Qualified__c, 'High score lead should be qualified');
        
        List<Task> tasks = [SELECT Subject, WhoId, OwnerId FROM Task WHERE WhoId = :highScoreLead.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task for qualified lead');
        System.assertEquals('Follow up on Qualified Lead', tasks[0].Subject);
    }
    
    @isTest 
    static void testLowScoreLeadNotQualified() {
        // Test low-scoring lead that should not be qualified
        Lead lowScoreLead = new Lead(
            LastName = 'LowScore',
            Company = 'Small Business',
            Industry = 'Other',
            Company_Size__c = 'Small',
            AnnualRevenue = 100000,
            Email = 'owner@smallbiz.com',
            Country = 'Other'
        );
        
        Test.startTest();
        insert lowScoreLead;
        Test.stopTest();
        
        Lead result = [SELECT Lead_Score__c, Qualified__c FROM Lead WHERE Id = :lowScoreLead.Id];
        System.assert(result.Lead_Score__c <= 80, 'Low score lead should have score <= 80');
        System.assert(!result.Qualified__c, 'Low score lead should not be qualified');
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lowScoreLead.Id];
        System.assertEquals(0, tasks.size(), 'Should not create task for unqualified lead');
    }
    
    @isTest 
    static void testLeadUpdateScoring() {
        // Test lead update scenario
        Lead lead = new Lead(
            LastName = 'UpdateTest',
            Company = 'Test Company',
            Industry = 'Other',
            Email = 'test@test.com'
        );
        insert lead;
        
        // Verify initial state
        Lead initialResult = [SELECT Lead_Score__c, Qualified__c FROM Lead WHERE Id = :lead.Id];
        System.assert(!initialResult.Qualified__c, 'Initially should not be qualified');
        
        // Update to make it qualified
        lead.Industry = 'Technology';
        lead.Company_Size__c = 'Large';
        lead.AnnualRevenue = 5500000;
        lead.Email = 'ceo@enterprise.com';
        lead.Country = 'USA';
        
        Test.startTest();
        update lead;
        Test.stopTest();
        
        Lead updatedResult = [SELECT Lead_Score__c, Qualified__c FROM Lead WHERE Id = :lead.Id];
        System.assert(updatedResult.Lead_Score__c > 80, 'Updated lead should have high score');
        System.assert(updatedResult.Qualified__c, 'Updated lead should be qualified');
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(1, tasks.size(), 'Should create task after qualification');
    }
    
    @isTest 
    static void testBulkLeadProcessing() {
        // Test bulk processing
        List<Lead> leads = new List<Lead>();
        
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                LastName = 'BulkTest' + i,
                Company = 'Company' + i,
                Industry = 'Technology',
                Company_Size__c = 'Large',
                AnnualRevenue = 2000000,
                Email = 'test' + i + '@corporate.com',
                Country = 'USA'
            ));
        }
        
        Test.startTest();
        insert leads;
        Test.stopTest();
        
        List<Lead> results = [SELECT Lead_Score__c, Qualified__c FROM Lead WHERE LastName LIKE 'BulkTest%'];
        System.assertEquals(200, results.size(), 'Should process all leads');
        
        for (Lead l : results) {
            System.assert(l.Lead_Score__c > 80, 'All bulk leads should have high scores');
            System.assert(l.Qualified__c, 'All bulk leads should be qualified');
        }
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :leads];
        System.assertEquals(200, tasks.size(), 'Should create tasks for all qualified leads');
    }
}