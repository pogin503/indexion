/**
 * Application entry point — sets up the event system.
 */
import { EventEmitter } from './events.js';
import { formatTimestamp } from './util.js';

/**
 * Logs an event with a timestamp prefix.
 * @param {string} name - Event name
 * @param {*} data - Event payload
 */
function logEvent(name, data) {
  const ts = formatTimestamp(Date.now());
  console.log(`[${ts}] ${name}:`, data);
}

/** Main application setup. */
function main() {
  const emitter = new EventEmitter();

  emitter.on('user:login', (user) => {
    logEvent('login', user);
  });

  emitter.on('user:logout', (user) => {
    logEvent('logout', { id: user.id });
  });

  // Simulate events
  emitter.emit('user:login', { id: 1, name: 'Alice' });
  emitter.emit('user:logout', { id: 1 });

  console.log(`Total listeners: ${emitter.listenerCount()}`);
}

export default main;
