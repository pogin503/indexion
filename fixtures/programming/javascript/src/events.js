/**
 * A simple event emitter — supports on, off, and emit.
 */

/** @class EventEmitter */
export class EventEmitter {
  constructor() {
    /** @type {Map<string, Function[]>} */
    this._listeners = new Map();
  }

  /**
   * Registers a listener for an event.
   * @param {string} event - Event name
   * @param {Function} fn - Callback function
   */
  on(event, fn) {
    if (!this._listeners.has(event)) {
      this._listeners.set(event, []);
    }
    this._listeners.get(event).push(fn);
  }

  /**
   * Emits an event, calling all registered listeners.
   * @param {string} event - Event name
   * @param {*} data - Data to pass to listeners
   */
  emit(event, data) {
    const fns = this._listeners.get(event);
    if (fns) {
      for (const fn of fns) {
        fn(data);
      }
    }
  }

  /** Returns the total number of registered listeners. */
  listenerCount() {
    let count = 0;
    for (const fns of this._listeners.values()) {
      count += fns.length;
    }
    return count;
  }
}
