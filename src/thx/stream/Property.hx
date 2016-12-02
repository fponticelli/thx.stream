package thx.stream;

using thx.stream.Subject;

class Property<T> {
  var value: T;
  var equals: T -> T -> Bool;
  var subjects: Array<Subject<T>>;

  public function new(initial: T, ?equals: T -> T -> Bool) {
    this.equals = null == equals ? Functions.equality : equals;
    this.subjects = [];
    set(initial);
  }

  public function modify(f: T -> T) {
    var newValue = f(value);
    if(equals(value, newValue))
      return;
    value = newValue;
    emit(Next(newValue));
  }

  public function get(): T
    return value;

  public function set(value: T)
    modify(function(_) return value);

  public function error(err: thx.Error)
    emit(Error(err));

  function emit(value: Message<T>)
    for(o in subjects)
      o.message(value);

  public function stream(): Stream<T>
    return Stream.cancellable(function(o, addCancel) {
      subjects.push(o);
      addCancel(function() {
        subjects.remove(o);
      });
      o.message(Next(value));
    });
}
