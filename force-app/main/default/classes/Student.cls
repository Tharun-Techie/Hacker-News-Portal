public with sharing class Student {
    public String name {get; set;}
    public Integer age {get; set;}
    public String std {get; set;}
    
    public Student(String name, Integer age, String std){
        this.name = name;
        this.age = age;
        this.std = std;    
    }
    
    public override String toString(){
        return 'Name: ' + name + ', Age: ' + age + ', Std: ' + std;
    }
}