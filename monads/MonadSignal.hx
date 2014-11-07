package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.*;

/** Monad instance for futures.
*/
class MonadSignal {
  public static function monad<T>(f : Void -> Signal<T>) return MonadSignal; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadSignal", body, Context);

  inline public static function ret<T>(x : T) : Void -> Signal<T> {
    return function() {
      var res = Signal.trigger();
      res.trigger(x);
      return res.asSignal();
    }
  }
  
  inline public static function map < T, U > (x : Void -> Signal<T>, f : T -> U) : Void -> Signal<U> {
    return function() {
      return x().map(f);
    }
  }

  inline public static function flatMap<T, U>(x : Void -> Signal<T>, f : T -> (Void -> Signal<U>)) : Void -> Signal<U> {
    return function() {
      var resTrigger = Signal.trigger();
      x().handle(
        function(t) {
          f(t)().handle(function(s) {resTrigger.trigger(s);});
        }
        );
      return resTrigger.asSignal();
    }
  }
}
