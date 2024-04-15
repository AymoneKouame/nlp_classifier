// is for one-line comment
/* is for multiline
comments - just like java
 * for data types see word doc in leaningSCALA
 folder*/

/* To open your browser with documentation for the element at the editor's caret, press ⇧F1 (View | External Documentation).
You must have the path to your browser set in the File | Settings | Web Browsers options and paths to documentation files added to
your project (File | Project Structure...) to use this feature.*/

print("I am learning scala")
println("I am learning scala") //i like this one's output
printf("I am leaning Scala")

10+3 *5 /2

"your answer"

var myName = "Aymone"
/*automatically deciphers the data
type for the defined variable and value of ''
 myName cab be changed*/

val myAge = 16 //I wish
/*automatically deciphers the data
type for the defined variable but value
 cannot be changed. it is a constant*/

/* integers have limited number of digits that can be added, whether decimals or not.
(like for most language). if you want to create a big interger you can
do it easily with the following
 */

val largeprime = BigInt("876381402472947924702472047272472472472047274204721645107382468245143")

val bigPi = BigDecimal("3.141592653589793238462643383279502884197169399375105820974944")

bigPi + 2

var randInt = 1000

randInt += 1

randInt
/*"randInt." shows you all the operators that you can have
to work with scala*/


"5+4 = " + (5 + 4)

"5*4 = " + (5*4)

"5 MUL by 4 = " + (5*4)

"5%4 = " + (5%4) // Remainder of the dividion of these two numbers

5*4

"thisValue" + 9  //concatenates it

randInt -=1

randInt

randInt /=4

randInt

randInt *=4

randInt


//MATH OPERATORS
// import scala math library so you xan do math operations
import scala.math._


scala.math.abs(-8)
//OR
abs(-8)

//absolute value

/*scala.math. will show all the math calculations you can
do with scala */

scala.math.sqrt(25)

scala.math.min(3,5)

scala.math.pow(3,2) + pow(5,2)

random()  //give me a random number

val R = random()

(random *(11-1) +1).toInt  //give me a random number between 1 and 10?
                          //and converts to integer



toRadians(90)
toRadians(1.5707963267948966)

/*conditional operators
== equal to; != not equal to
>
<
>=
<=
Logical operators
&& (AND)
|| (OR)
! (NOT)
*/


var age = 18

val canVote =if(age >=18) "yes" else "no"
canVote

if (age >= 5) && (age <= 6){
  println ("Go to Kindergarten")
  } else if(age>6) && (age <=7) {
  println("Go to grade" + (age - 5))
} else {println("yay")
}
/*should print something. but there
is a bug in IntelliJ that does not recognize
&&??*/

true || false //should work

//------------------

val RISK_INDICATOR_CORRELATIONS = Map(

  RiskFactorType.AVAILABILITY -> Map(
    CYBER_IQ -> 1.0,
    MATURITY -> 1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.BYOD -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> 1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.COMPLIANCE -> Map(
    CYBER_IQ -> 1.0,
    MATURITY -> 1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.CONFIDENTIALITY -> Map(
    CYBER_IQ -> 1.0,
    MATURITY -> 0.0,
    SCALE -> 1.0
  ),
  RiskFactorType.DATA_INTEGRITY -> Map(
    CYBER_IQ -> 1.0,
    MATURITY -> 1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.EXEC_BUYIN -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.FINANCIAL -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> -1.0
  ),
  RiskFactorType.NETWORK_RESOURCES -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> -1.0
  ),
  RiskFactorType.NETWORK_SECURITY -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.NO_RECOVERY -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.OUTDATED -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.PHYSICAL_SECURITY -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.RAPID_GROWTH -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> -1.0
  ),
  RiskFactorType.SECURITY_STAFF -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.SPECIFICALLY_TARGETED -> Map(
    CYBER_IQ -> 1.0,
    MATURITY -> 0.0,
    SCALE -> 1.0
  ),
  RiskFactorType.THIRD_PARTIES -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> 1.0
  ),
  RiskFactorType.TURNOVER -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.UNUSUAL -> Map(
    CYBER_IQ -> 0.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  ),
  RiskFactorType.VISIBILITY -> Map(
    CYBER_IQ -> -1.0,
    MATURITY -> -1.0,
    SCALE -> 0.0
  )
)




