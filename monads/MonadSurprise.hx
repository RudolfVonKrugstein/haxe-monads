package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.Future;
import tink.core.Outcome;
import tink.core.Noise;

using tink.core.Outcome;

/** Monad instance for surprises.
*/
class MonadSurprise {
  public static function monad<T>(f : Surprise<T, String>) return MonadSurprise; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadSurprise", body, Context);

  inline public static function ret<T>(x : T) : Surprise<T, String> {
    var res = Future.trigger();
    res.trigger(Success(x));
    return res.asFuture();
  }
  
  inline public static function map < T, U > (x : Surprise<T, String>, f : T -> U) : Surprise<U, String> {
    return x.map(function(o) {
      return o.map(f);
      });
  }

  inline public static function flatMap<T, U>(x : Surprise<T,String>, f : T -> (Surprise<U,String>)) : Surprise<U,String> {
    var resTrigger = Future.trigger();
    x.handle(function(t) {
      switch(t) {
        case Failure(s):
        resTrigger.trigger(Failure(s));
        case Success(v):
        f(v).handle(resTrigger.trigger);
      }
      });
    return resTrigger.asFuture();
  }

  public static function toNoise<T>(f : Surprise<T,String>) : Surprise<Noise,String> {
    return map(f, function(t) {return Noise;});
  }

  public static function ofMany<T>(f : Array<Surprise<T, String>>) : Surprise<Array<T>, String> {
    var resArray  = [];
    var resFuture = Future.trigger();
    function iterate(index : Int) : Void {
      if (f.length <= index) {
        resFuture.trigger(Success(resArray));
      } else {
        f[index].handle(
          function(t) {
            switch(t) {
              case Failure(e):
              resFuture.trigger(Failure(e));
              case Success(s):
              resArray.push(s);
              iterate(index + 1);
            }
            });
      }
    }
    iterate(0);
    return resFuture.asFuture();
  }

  public static function ofManyNoise(f : Array<Surprise<Noise, String>>) : Surprise<Noise, String> {
    var resFuture = Future.trigger();
    function iterate(index : Int) : Void {
      if (f.length <= index) {
        resFuture.trigger(Success(Noise));
        } else {
          f[index].handle(
            function(t) {
              switch(t) {
                case Failure(e):
                resFuture.trigger(Failure(e));
                case Success(s):
                iterate(index +1);
              }
              });
        }
      }
      iterate(0);
      return resFuture.asFuture();
    }
}
