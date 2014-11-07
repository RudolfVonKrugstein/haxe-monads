package monads;

import tink.core.Outcome;

class MonadOutcome {
  /** If there is any failure in the input, take that. Otherwise return Array of non failures.
  */
  static public function ofMany<R,F>(i : Array<Outcome<R,F>>) : Outcome<Array<R>,F> {
    var res = [];
    for (e in i) {
      switch(e) {
        case Failure(f):
        return Failure(f);
        case Success(r):
        res.push(r);
      }
    }
    return Success(res);
  }
}
