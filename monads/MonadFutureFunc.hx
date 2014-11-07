package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.*;
import tink.core.Noise;

/** Monad instance for future functions (functions returning futures).
*   Very similar to MonadFuture, but with functions returning futures. I am not sure if this monad really has a
*   purpose that could be fulliflled by MonadFuture.
*/
class MonadFutureFunc {
  public static function monad<T>(f : Void -> Future<T>) return MonadFutureFunc; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadFutureFunc", body, Context);

  inline public static function ret<T>(x : T) : Void -> Future<T> {
    return function() {
      var res = Future.trigger();
      res.trigger(x);
      return res;
    }
  }
  
  inline public static function map < T, U > (x : Void -> Future<T>, f : T -> U) : Void -> Future<U> {
    return function() {
      return x().map(f);
    }
  }

  inline public static function flatMap<T, U>(x : Void -> Future<T>, f : T -> (Void -> Future<U>)) : Void -> Future<U> {
    return function() {
      var resTrigger = Future.trigger();
      x().handle(
        function(t) {
          f(t)().handle(resTrigger.trigger);
        }
        );
      return resTrigger.asFuture();
    }
  }

  public static function toNoise<T>(f : Void -> Future<T>) : Void -> Future<Noise> {
    return map(f, function(t) {return Noise;});
  }

  public static function ofMany<T>(f : Array<Void -> Future<T>>, stop : T -> Bool = null) : Void -> Future<Array<T>> {
    return function() {
      var resArray  = [];
      var resFuture = Future.trigger();
      function iterate(index : Int) : Void {
        if (f.length <= index) {
          resFuture.trigger(resArray);
        } else {
          f[index]().handle(
            function(t) {
              resArray.push(t);
              if (stop != null && stop(t)) {
                resFuture.trigger(resArray);
              } else {
                iterate(index + 1);
              }
              });
        }
      }
      iterate(0);
      return resFuture.asFuture();
    }
  }

  public static function ofManyNoise(f : Array<Void -> Future<Noise>>) : Void -> Future<Noise> {
    return function() {
      var resFuture = Future.trigger();
      function iterate(index : Int) : Void {
        if (f.length <= index) {
          resFuture.trigger(Noise);
        } else {
          f[index]().handle(
            function(t) {
              iterate(index + 1);
              });
        }
      }
      iterate(0);
      return resFuture.asFuture();
    }
  }
}
