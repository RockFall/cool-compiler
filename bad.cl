
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)

(* no error *)
class A {
};

(* error *)
class A2 {
    ana(a : Int) : Int {
        {
            (*{15; 15; bc};*)
            (*(16; Bc; 15;};*)
            250;
        }
    };
    bnb(a : Int) : Int {
        {
            let A:Int in 1+X;
            250;
        }
    };
};


(* error: wrong formals *)
class F {
    ana(, a : Int) : Int {
        3
    };
};

(* error:  b is not a type identifier *)
Class b inherits A {
};

(* error:  a is not a type identifier *)
Class C inherits a {
};

(* error:  keyword inherits is misspelled *)
Class D inherts A {
};

(* error:  closing brace is missing *)
Class E inherits A {
;