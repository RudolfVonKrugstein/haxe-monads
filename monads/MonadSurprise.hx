package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.Future;
import tink.core.Outcome;
import tink.core.Noise;

using tink.core.Outcome;

/** Monad for Surprises. See MonadFuture. In difference to MonadFuture the next Future (Surprise) returning function is only
  * run, when the last Surprise is not a Failure. It is assumed that all Failures are Strings!
*/
class MonadSurprise {
  public static function monad<T,F>(f : Surprise<T, F>) return MonadSurprise; // will help with syntactic Sugar (see below)

  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadSurprise", body, Context);

  inline public static function ret<T,F>(x : T) : Surprise<T, F> {
    var res = Future.trigger();
    res.trigger(Success(x));
    return res.asFuture();
  }
  
  inline public static function map < T, U, F > (x : Surprise<T, F>, f : T -> U) : Surprise<U, F> {
    return x.map(function(o) {
      return o.map(f);
      });
  }

  inline public static function flatMap<T, U, F>(x : Surprise<T,F>, f : T -> (Surprise<U,F>)) : Surprise<U,F> {
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

  public static function toNoise<T,F>(f : Surprise<T,F>) : Surprise<Noise,F> {
    return map(f, function(t) {return Noise;});
  }

  public static function ofMany<T,F>(f : Array<Surprise<T, F>>) : Surprise<Array<T>, F> {
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

  public static function ofManyNoise<F>(f : Array<Surprise<Noise, F>>) : Surprise<Noise, F> {
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
