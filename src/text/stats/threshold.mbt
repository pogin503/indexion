///|
/// Statistical threshold functions for separating signal from noise in
/// sorted weight distributions.

///|
/// Kneedle algorithm for finding the elbow (knee) point in a descending-sorted
/// weight array. Returns the number of items before the knee — i.e., the count
/// of "significant" items in the foreground class.
///
/// For a decreasing curve, the knee is the point that deviates most below
/// the straight line connecting the first and last points. This corresponds
/// to the sharpest transition from high-weight signal to low-weight noise.
///
/// The input array MUST be sorted in descending order.
///
/// Reference: Satopaa et al., "Finding a 'Kneedle' in a Haystack", 2011.
pub fn kneedle_threshold_index(weights : Array[Double]) -> Int {
  let n = weights.length()
  if n <= 1 {
    return n
  }
  if n == 2 {
    let ratio = if weights[0] > 0.0 { weights[1] / weights[0] } else { 1.0 }
    return if ratio > 0.5 { 2 } else { 1 }
  }
  let x_max = (n - 1).to_double()
  let y_min = weights[n - 1]
  let y_max = weights[0]
  let y_range = y_max - y_min
  if y_range <= 0.0 {
    return n
  }
  // Compute D_n = y_norm - y_line for each point.
  // y_line is the value on the straight line from (0, 1) to (1, 0).
  // The knee is where D_n is most negative.
  let mut best_idx = 0
  let mut best_dn = 0.0
  for i = 0; i < n; i = i + 1 {
    let x_norm = i.to_double() / x_max
    let y_norm = (weights[i] - y_min) / y_range
    let y_line = 1.0 - x_norm
    let dn = y_norm - y_line
    if dn < best_dn {
      best_dn = dn
      best_idx = i
    }
  }
  if best_idx < 1 { 1 } else { best_idx }
}
