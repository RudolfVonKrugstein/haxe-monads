package monads;

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;
import tink.core.*;
import tink.core.Noise;

/** Monad instance for futures.
*/
class MonadContinuation {
  public static function monad<T>(f : Callback<T> -> Void) return MonadContinuation; // will help with syntactic Sugar (see below)
    
  macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
    Monad._dO("monads.MonadContinuation", body, Context);

  inline public static function ret<T>(x : T) : Callback<T> -> Void {
    return function(cb) {
      cb.invoke(x);
    }
  }
  
  inline public static function map < T, U > (x : Callback<T> -> Void, f : T -> U) : Callback<U> -> Void {
    return function(cb) {
      x(function(t) {
        cb.invoke(f(t));
      });
    }
  }

  inline public static function flatMap<T, U>(x : Callback<T> -> Void, f : T -> (Callback<U> -> Void)) : Callback<U> -> Void {
    return function(cb) {
      x(function(t) {
        f(t)(cb);
      });
    }
  }

  public static function toCont<T>(s : Void -> Future<T>) : Callback<T> -> Void {
    return function(cb) {
      s().handle(function(t) {cb.invoke(t);});
    }
  }

  public static function toNoiseCont(f : Void -> Void) : Callback<Noise> -> Void {
    return function(cb) {
      f();
      cb.invoke(Noise);
    }
  }
}
