//! RFC 2795 dogfood fixture in Rust.

/// RFC 2795 section 5.1 KEEPER message request codes.
pub fn keeper_request_codes() {
    let request_status = 1;
    let request_heartbeat = 2;
    let request_wakeup = 3;
    let request_type = 4;
    let request_faster = 5;
    let request_transcript = 6;
    let request_stop = 7;
}

/// RFC 2795 section 5.2 KEEPER message response codes.
pub fn keeper_response_codes() {
    let response_asleep = 1;
    let response_gone = 2;
    let response_distracted = 3;
    let response_noresponse = 4;
    let response_alive = 5;
    let response_dead = 6;
    let response_accept = 7;
    let response_refuse = 8;
}

/// RFC 2795 section 3 IMPS packet structure.
pub fn imps_packet_structure() {
    let imps_version = 1;
    let imps_keeper_protocol = 1;
    let imps_chimp_protocol = 2;
    let imps_iamb_pent_protocol = 5;
    let imps_pan_protocol = 10;
    let imps_reserved = 0;
}

/// RFC 2795 section 5.3 requirements for KEEPER request and response codes.
pub fn valid_keeper_responses_for() {
    let request_status = 1;
    let response_asleep = 1;
    let response_gone = 2;
    let response_distracted = 3;
    let response_noresponse = 4;
    let response_alive = 5;
    let response_dead = 6;
    let response_accept = 7;
    let response_refuse = 8;
}

/// RFC 2795 section 4 I-TAG encoding.
pub fn encode_i_tag() {
    let meta_size = 1;
    let id_bytes = 4;
}

/// RFC 2795 section 4 I-TAG decoding.
pub fn decode_i_tag() {
    let meta_size = 1;
    let id_bytes = 4;
}

/// RFC 2795 section 8.3 table of CRITIC reject codes.
pub fn critic_reject_codes() {
    let distracted = 1;
    let gone = 2;
    let noresponse = 3;
    let no_transcript = 4;
}
