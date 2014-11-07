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
  public static function monad<T>(f : Void -> Surprise<T,String>) return MonadSurpriseFunc; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadSurpriseFunc", body, Context);

  inline public static function ret<T>(x : T) : Void -> Surprise<T,String> {
    return function() {
      var res = Future.trigger();
      res.trigger(Success(x));
      return res;
    }
  }
  
  inline public static function map < T, U > (x : Void -> Surprise<T,String>, f : T -> U) : Void -> Surprise<U, String> {
    return function() {
      return x().map(function(o) return o.map(f));
    }
  }

  inline public static function flatMap<T, U>(x : Void -> Surprise<T,String>, f : T -> (Void -> Surprise<U,String>)) : Void -> Surprise<U,String> {
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

  public static function toNoise<T>(f : Void -> Surprise<T,String>) : Void -> Surprise<Noise,String> {
    return map(f, function(t) {return Noise;});
  }

  public static function ofMany<T>(f : Array<Void -> Surprise<T,String>>) : Void -> Surprise<Array<T>,String> {
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

  public static function ofManyNoise(f : Array<Void -> Surprise<Noise,String>>) : Void -> Surprise<Noise,String> {
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
