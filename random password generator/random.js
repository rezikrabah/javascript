

function generatepassword(length,includelowercase, includeuppercase,includenumbers){

const lowercasechars = "abcdefghijklmnopqrstuvwxyz";
const uppercasechars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const numberchars  = "0123456789";



let allowdchars = "";
let password= "";

allowdchars +=includelowercase? lowercasechars:"";
allowdchars +=includeuppercase? uppercasechars:"";
allowdchars +=includenumbers? numberchars:"";
  if(length <= 0){
        return `(password length must be at least 1)`;
    }
    if(allowdchars.length === 0){
        return `(At least 1 set of character needs to be selected)`;
    }

    for(let i = 0; i < length; i++){
        const randomIndex = Math.floor(Math.random() * allowdchars.length);
        password += allowdchars[randomIndex];
    }

    return password;
}






const passwordlength=12;
const includelowercase = true;
const includeuppercase = true ;
const invludenumbers = true;
const includesymbols= true;


 const password =  generatepassword(passwordlength,
                                   includelowercase,
                                   includeuppercase,
                                     invludenumbers,
                                    includesymbols);
       console.log(`generated password: ${password}`) ;                            
