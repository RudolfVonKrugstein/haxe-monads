package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.Outcome;
import tink.core.Noise;

using tink.core.Outcome;

/** Monad for Surprises. See MonadFuture. In difference to MonadFuture the next Future (Surprise) returning function is only
  * run, when the last Surprise is not a Failure. It is assumed that all Failures are Strings!
*/
class MonadOutcome {
  public static function monad<T,F>(f : Outcome<T, F>) return MonadOutcome; // will help with syntactic Sugar (see below)

  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadOutcome", body, Context);

  inline public static function ret<T,F>(x : T) : Outcome<T, F> {
    return Success(x);
  }
  
  inline public static function map < T, U, F > (x : Outcome<T, F>, f : T -> U) : Outcome<U, F> {
    return x.map(f);
  }

  inline public static function flatMap<T, U, F>(x : Outcome<T,F>, f : T -> (Outcome<U,F>)) : Outcome<U,F> {
    return switch(x) {
      case Failure(f): Failure(f);
      case Success(s): f(s);
    }
  }

  public static function toNoise<T,F>(f : Outcome<T,F>) : Outcome<Noise,F> {
    return map(f, function(t) {return Noise;});
  }
}
