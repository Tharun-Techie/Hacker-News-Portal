public without sharing class UtilityClass {
    public UtilityClass() {

    }

    public static List<Account> generateDummyAccounts(Integer numOfAccont){
        
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < numOfAccont; i++) {
            String name = generateFullName();
            String accountNumber = String.valueOf(Math.abs(Crypto.getRandomLong()));
            List<Integer> options = new List<Integer>{7, 8, 9};
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), options.size());
            Integer chosenNumber = options[randomIndex];
            String phNo = String.valueOf(chosenNumber) + String.valueOf(Integer.valueOf(Math.floor(Math.random() * 1000000000)));
            String isActive = 'Yes';
            String email = name.replace(' ', '.').toLowerCase() + '@example.com';
        
            Account acc = new Account();
            
            acc.Name = name;
            acc.AccountNumber = accountNumber;
            acc.Phone = phNo;
            acc.Active__c = isActive;
            acc.Email__c = email;
            
            accList.add(acc);
        }
            return accList;
            
        }
            
            

            


public static List<Account> generateAccounts(Integer numOfAccounts) {
    List<Account> accList = new List<Account>();
    
    for (Integer i = 0; i < numOfAccounts; i++) {
        // Generate unique name and details to prevent duplicates
        String name = generateFullName();
        String accountNumber = String.valueOf(Math.abs(Crypto.getRandomLong())); 
        
        List<Integer> options = new List<Integer>{7, 8, 9};
        Integer chosenNumber = options[Math.mod(Math.abs(Crypto.getRandomInteger()), options.size())];
        
        // Generate 9-digit random phone number
        String phNo = String.valueOf(chosenNumber) + String.valueOf(Math.abs(Crypto.getRandomLong())).substring(0, 9);
        
        List<String> emailDomainList = new List<String>{'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com', 'aol.com', 'msn.com', 'comcast.net', 'live.com', 'gmx.de'};
        String emailDomain = emailDomainList[Math.mod(Math.abs(Crypto.getRandomInteger()), emailDomainList.size())];
        String email = name.replace(' ', '.').toLowerCase() + phNo.substring(6, 10) + '@' + emailDomain;
        
        Account acc = new Account(
            Name = name,
            AccountNumber = accountNumber,
            Phone = phNo,
            Active__c = 'Yes',
            Email__c = email
        );
        accList.add(acc);
    }
    return accList;
}



    public static String generateFirstName(){
        List<String> firstName = new List<String>{'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan', 'Shaurya', 'Atharv', 'Kabir', 'Aarush', 'Rudra', 'Darsh', 'Dev', 'Om', 'Vihan', 'Rohan', 'Aadhya', 'Ananya', 'Pari', 'Diya', 'Pranavi', 'Avni', 'Saanvi', 'Shanaya', 'Khushi', 'Prisha', 'Riya', 'Siya', 'Navya', 'Meera', 'Arya', 'Ira', 'Anaisha', 'Myra', 'Amaira', 'Angel', 'Zoya', 'Fatima', 'Aanya', 'Kiara', 'Ahana', 'Sarah', 'Kavya', 'Samaira', 'Trisha', 'Suhani'};
        Integer firstIndex = (Integer)Math.floor(Math.random() * firstName.size());
         return firstName.get(firstIndex);
    }
    public static String generateLastName(){
        List<String> lastName = new List<String>{'Sharma', 'Verma', 'Gupta', 'Singh', 'Kumar', 'Das', 'Mehta', 'Kaur', 'Reddy', 'Rao', 'Patel', 'Joshi', 'Sen', 'Chowdhury', 'Dutta', 'Bose', 'Chatterjee', 'Banerjee', 'Mukherjee', 'Roy', 'Chakraborty', 'Dasgupta', 'Sengupta', 'Basu', 'Ghosh', 'Mitra', 'Nath', 'Paul', 'Deb', 'Barman', 'Sarkar', 'Majumdar', 'Thakur', 'Deshmukh', 'Kulkarni', 'Jadhav', 'Shinde', 'Pawar', 'More', 'Gaikwad', 'Sawant', 'Chavan', 'Salunkhe', 'Thorat', 'Bhosale', 'Bhandari', 'Naik', 'Hebbar', 'Ranganath', 'Swamy'};
        Integer lastIndex = (Integer)Math.floor(Math.random() * lastName.size());
         return lastName.get(lastIndex);
    }
    public static String generateFullName(){
        return generateFirstName() + ' ' + generateLastName();
    }
}


