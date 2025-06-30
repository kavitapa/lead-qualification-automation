public class LeadScoringHelper {
    public static Integer calculateScore(Lead l) {
        Integer score = 0;
        
        // Industry scoring
        if (l.Industry == 'Technology') {
            score += 25;
        } else if (l.Industry == 'Finance') {
            score += 20;
        } else if (l.Industry == 'Healthcare') {
            score += 15;
        }
        
        // Company size scoring
        if (l.Company_Size__c == 'Large') {
            score += 30;
        } else if (l.Company_Size__c == 'Medium') {
            score += 20;
        } else if (l.Company_Size__c == 'Small') {
            score += 10;
        }
        
        // Revenue scoring
        if (l.AnnualRevenue != null) {
            if (l.AnnualRevenue > 5000000) {
                score += 25;
            } else if (l.AnnualRevenue > 1000000) {
                score += 20;
            } else if (l.AnnualRevenue > 500000) {
                score += 15;
            }
        }
        
        // Email domain scoring
        if (l.Email != null) {
            if (l.Email.contains('@fortune500.com') || l.Email.contains('@enterprise.com')) {
                score += 15;
            } else if (l.Email.contains('@corporate.com') || l.Email.contains('@company.com')) {
                score += 10;
            }
        }
        
        // Country scoring
        if (l.Country == 'USA' || l.Country == 'United States') {
            score += 15;
        } else if (l.Country == 'Canada' || l.Country == 'UK' || l.Country == 'Germany') {
            score += 10;
        }
        
        return score;
    }
}