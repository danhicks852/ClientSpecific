#deprecated method
$newobject = New-Object -TypeName PSObject
$newobject | Add-Member -MemberType NoteProperty -Name Name -Value "Bob"
$newobject | Add-Member -MemberType NoteProperty -Name LastName -Value "Smith"
$newobject | Add-Member -MemberType NoteProperty -Name Age -Value 50
$newobject

#standard for small amounts of data
$newobject2 = [PSCustomObject]@{
    Name = "Mary"
    LastName = "Smith"
    Age = 30 
}
$newobject2

#Standard for huge amounts of data. Only works with PS5+
class Person {
    [string]$Name
    [string]$LastName
    [int]$Age
    #you can use functions in a class.
    [String]GetFullName(){
        return "$($this.Name) $($this.LastName)"
    }
}
$newobject3 = [Person]::new()
$newobject3.Name = "John"
$newobject3.LastName = "Smith"
$newObject3.Age = 40
$newObject3
$newObject3.GetFullName()
# double colons are to reference static methods for the class (preexisting functions in the class)
