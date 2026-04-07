/**
 * RFC 2795 section 5.1 and 5.2 KEEPER message request and response codes.
 * Requests: STATUS=1, HEARTBEAT=2, WAKEUP=3, TYPE=4, FASTER=5, TRANSCRIPT=6, STOP=7.
 * Responses: ASLEEP=1, GONE=2, DISTRACTED=3, NORESPONSE=4, ALIVE=5, DEAD=6, ACCEPT=7, REFUSE=8.
 */
export const REQUEST_STATUS = 1
export const REQUEST_HEARTBEAT = 2
export const REQUEST_WAKEUP = 3
export const REQUEST_TYPE = 4
export const REQUEST_FASTER = 5
export const REQUEST_TRANSCRIPT = 6
export const REQUEST_STOP = 8

export const RESPONSE_ASLEEP = 1
export const RESPONSE_GONE = 2
export const RESPONSE_DISTRACTED = 3
export const RESPONSE_NORESPONSE = 4
export const RESPONSE_ALIVE = 5
export const RESPONSE_DEAD = 6
export const RESPONSE_ACCEPT = 7
export const RESPONSE_REFUSE = 8
