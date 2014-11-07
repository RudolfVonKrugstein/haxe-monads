package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.*;
import tink.core.Noise;

/** Monad instance for futures.
*/
class MonadFuture {
  public static function monad<T>(f : Future<T>) return MonadFuture; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadFuture", body, Context);

  inline public static function ret<T>(x : T) : Future<T> {
    var res = Future.trigger();
    res.trigger(x);
    return res;
  }
  
  inline public static function map < T, U > (x : Future<T>, f : T -> U) : Future<U> {
    return x.map(f);
  }

  inline public static function flatMap<T, U>(x : Future<T>, f : T -> Future<U>) : Future<U> {
    var resTrigger = Future.trigger();
    x.handle(
      function(t) {
        f(t).handle(resTrigger.trigger);
      });
    return resTrigger.asFuture();
  }

  public static function toNoise<T>(f : Future<T>) : Future<Noise> {
    return f.map(function (t) {return Noise;});
  }

  public static function ofMany<T>(f : Array<Future<T>>) : Future<Array<T>> {
    var resArray  = [];
    var resFuture = Future.trigger();
    function iterate(index : Int) : Void {
      if (f.length <= index) {
        resFuture.trigger(resArray);
      } else {
        f[index].handle(
          function(t) {
            resArray.push(t);
            iterate(index + 1);
            });
      }
    }
    iterate(0);
    return resFuture.asFuture();
  }

  public static function ofManyNoise(f : Array<Future<Noise>>) : Future<Noise> {
    var resFuture = Future.trigger();
    function iterate(index : Int) : Void {
      if (f.length <= index) {
        resFuture.trigger(Noise);
      } else {
        f[index].handle(
          function(t) {
            iterate(index + 1);
            });
      }
    }
    iterate(0);
    return resFuture.asFuture();
  }
}
