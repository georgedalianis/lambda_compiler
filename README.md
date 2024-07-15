# lambda_compiler
A) Για την μετατροπή ενός αρχείου .la σε αρχείο .c 
   ./compile.sh examples/useless.la

   Εφόσον δεν υπάρχουν συντακτικά λάθη θα παραχθεί ένα αρχείο useless.c

   Το script compile.sh πριν από κάθε εκτέλεση "ξαναφτιάχνει" τον mycompiler πριν τον χρησιμοποιήσει 
   για την μεταγλώτιση αρχείων .la

B) Για την εκτέλεση του .c αρχείου που παράχθηκε:

   Εντός του directory των examples 
   
   Compile χρησιμοποιώντας τον compiler της C:

   gcc -o useless useless.c 

   Θα παραχθεί ένα εκτελεσιμο useless αρχείο που εκτελείται στην κονσόλα ως εξής:
    
   ./useless 
