package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.*;
import tink.core.Future;
import tink.core.Outcome;
import tink.core.Noise;
using tink.core.Outcome;

/** Monad instance for Surprise functions (functions returning Surprises).
*/
class MonadSurpriseFunc {
  public static function monad<T,F>(f : Void -> Surprise<T,F>) return MonadSurpriseFunc; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadSurpriseFunc", body, Context);

  inline public static function ret<T,F>(x : T) : Void -> Surprise<T,F> {
    return function() {
      var res = Future.trigger();
      res.trigger(Success(x));
      return res;
    }
  }
  
  inline public static function map < T, U ,F> (x : Void -> Surprise<T,F>, f : T -> U) : Void -> Surprise<U, F> {
    return function() {
      return x().map(function(o) return o.map(f));
    }
  }

  inline public static function flatMap<T, U, F>(x : Void -> Surprise<T,F>, f : T -> (Void -> Surprise<U,F>)) : Void -> Surprise<U,F> {
    return function() {
      var resTrigger = Surprise.trigger();
      x().handle(
        function(r) {
          switch(r) {
            case Failure(s):
            resTrigger.trigger(Failure(s));
            case Success(t):
            f(t)().handle(resTrigger.trigger);
          }
        }
        );
      return resTrigger.asFuture();
    }
  }

  public static function toNoise<T,F>(f : Void -> Surprise<T,F>) : Void -> Surprise<Noise,F> {
    return map(f, function(t) {return Noise;});
  }

  public static function ofMany<T,F>(f : Array<Void -> Surprise<T,F>>) : Void -> Surprise<Array<T>,F> {
    return function() {
      var resArray  = [];
      var resSurprise = Future.trigger();
      function iterate(index : Int) : Void {
        if (f.length <= index) {
          resSurprise.trigger(Success(resArray));
        } else {
          f[index]().handle(
            function(r) {
              switch(r) {
                case Failure(s):
                resSurprise.trigger(Failure(s));
                case Success(t):
                resArray.push(t);
                iterate(index +1);
              }
              });
        }
      }
      iterate(0);
      return resSurprise.asFuture();
    }
  }

  public static function ofManyNoise<F>(f : Array<Void -> Surprise<Noise,F>>) : Void -> Surprise<Noise,F> {
    return function() {
      var resSurprise = Future.trigger();
      function iterate(index : Int) : Void {
        if (f.length <= index) {
          resSurprise.trigger(Success(Noise));
        } else {
          f[index]().handle(
            function(r) {
              switch(r) {
                case Failure(s):
                resSurprise.trigger(Failure(s));
                case Success(_):
                iterate(index +1);
              }
              });
        }
      }
      iterate(0);
      return resSurprise.asFuture();
    }
  }
}
